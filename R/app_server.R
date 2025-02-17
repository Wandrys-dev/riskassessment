#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @importFrom shinyjs show hide delay runjs
#' @importFrom shinymanager secure_server check_credentials
#' @importFrom keyring key_get
#' @importFrom loggit loggit
#' @noRd
app_server <- function(input, output, session) {
  # Collect user info.
  user <- reactiveValues()
  user$metrics_reweighted <- 0
  
  # check_credentials directly on sqlite db
  res_auth <- shinymanager::secure_server(
    check_credentials = shinymanager::check_credentials(
      credentials_name,
      passphrase = passphrase
    )
  )
  
  observeEvent(res_auth$user, {
    if (res_auth$admin == TRUE) {
      appendTab("apptabs",
                tabPanel(
                  title = div(id = "admin-mode-tab", icon("gears"), "Administrative Tools"),
                  h2("Administrative Tools & Options", align = "center", `padding-bottom`="20px"),
                  br(),
                  tabsetPanel(
                    id = "credentials",
                    tabPanel(
                      id = "credentials_id",
                      title = "Credential Manager",
                      shinymanager:::admin_ui("admin")
                    ),
                    tabPanel(
                      id = "reweight_id",
                      title = "Assessment Reweighting",
                      reweightViewUI("reweightInfo")
                    )
                  ),
                  tags$script(HTML("document.getElementById('admin-add_user').style.width = 'auto';"))
                ))
    } else {
      removeTab(inputId = "apptabs", target = "admin-mode-tab")
    }
  }, priority = 1)
  
  purrr::walk(paste("admin", c("edited_user", "edited_mult_user", "delete_selected_users", "delete_user", "changed_password", "changed_password_users"), sep = "-"),
              ~ observeEvent(input[[.x]], removeModal(), priority = 1))
  
  purrr::walk(c("admin-reseted_password", "admin-changed_password", "admin-added_user"),
              ~ observeEvent(input[[.x]], shinyjs::runjs("document.body.setAttribute('data-bs-overflow', 'auto');"), priority = -1))
  
  purrr::walk(paste("admin", c("edit_mult_user", "edit_user", "add_user"), sep = "-"),
              function(.x) {
                y <- ifelse(.x == "admin-edit_mult_user", "admin-edit_selected_users", .x)
                observeEvent(input[[y]], {
                  shinyjs::runjs(paste0("document.getElementById('", .x, c("-start-", "-expire-", "-user-"), "label').innerHTML = ", c("'Start Date'", "'Expiration Date'", "'User Name'"), collapse = ";\n"))
                }, priority = -1)
              })
  
  purrr::walk(paste("admin", c("edited_user", "edited_mult_user", "added_user", "changed_password", "reset_pwd", "changed_password_users"), sep = "-"),
              ~ observeEvent(input[[.x]], {
                shinyjs::delay(1000,
                               shinyjs::runjs("
                   var elements = document.getElementsByClassName('shiny-notification');
                   var sendToR = [];
                   for (var i = 0; i < elements.length; i++) {
                      sendToR.push(elements[i].id);
                   }
                   Shiny.onInputChange('shinyjs-returns', sendToR)
                   "))
              }, priority = -2))
  
  observeEvent(input$`shinyjs-returns`, {
    purrr::walk(input$`shinyjs-returns`, ~ removeNotification(stringr::str_remove(.x, "shiny-notification-")))
  })
  
  observeEvent(input$`table_users-returns`, {
    shinyjs::runjs("
                   $($('#admin-table_users').find('table').DataTable().column(0).header()).text('user name');
                   $($('#admin-table_users').find('table').DataTable().column(1).header()).text('start date');
                   $($('#admin-table_users').find('table').DataTable().column(2).header()).text('expiration date');")
  })
  
  observeEvent(input$`table_pwds-returns`, {
    shinyjs::runjs("
                   $($('#admin-table_pwds').find('table').DataTable().column(0).header()).text('user name');
                   $($('#admin-table_pwds').find('table').DataTable().column(3).header()).text('date last changed');")
  })
  
  # Save user name and role.  
  observeEvent(res_auth$user, {
    if (res_auth$admin == TRUE)
      loggit::loggit("INFO", glue::glue("User {res_auth$user} signed on as admin"))
    
    user$name <- trimws(res_auth$user)
    user$role <- trimws(ifelse(res_auth$admin == TRUE, "admin", "user"))
  })
  
  # Load server of the reweightView module.
  metric_weights <- reweightViewServer("reweightInfo", user)
  
  # Load server of the uploadPackage module.
  uploaded_pkgs <- uploadPackageServer("upload_package")
  
  # Load server of the sidebar module.
  selected_pkg <- sidebarServer("sidebar", user, uploaded_pkgs$names)
  
  changes <- reactiveVal(0)
  observe({
    changes(changes() + 1)
  }) %>%
    bindEvent(selected_pkg$decision(), selected_pkg$overall_comment_added())
  
  # Load server of the assessment criteria module.
  assessmentInfoServer("assessmentInfo", metric_weights = metric_weights)
  
  # Load server of the database view module.
  databaseViewServer("databaseView", user, uploaded_pkgs$names,
                     metric_weights = metric_weights, changes)
  
  # Gather maintenance metrics information.
  maint_metrics <- reactive({
    req(selected_pkg$name())
    req(selected_pkg$name() != "-")
    
    # Collect all the metric names and values associated to package_id.
    get_mm_data(selected_pkg$id())
  })
  
  
  # Gather community usage metrics information.
  community_usage_metrics <- reactive({
    req(selected_pkg$name())
    req(selected_pkg$name() != "-")
    
    get_comm_data(selected_pkg$name())
  })
  
  # Load server for the maintenance metrics tab.
  maintenance_data <- maintenanceMetricsServer('maintenanceMetrics',
                                               selected_pkg,
                                               maint_metrics,
                                               user)
  
  # Load server for the community metrics tab.
  community_data <- communityMetricsServer('communityMetrics',
                                           selected_pkg,
                                           community_usage_metrics,
                                           user)
  
  # Load server of the report preview tab.
  reportPreviewServer(id = "reportPreview",
                      selected_pkg = selected_pkg,
                      maint_metrics = maint_metrics,
                      com_metrics = community_data$cards,
                      com_metrics_raw = community_usage_metrics,
                      mm_comments = maintenance_data$comments,
                      cm_comments = community_data$comments,
                      downloads_plot_data = community_data$downloads_plot_data,
                      user = user,
                      app_version = app_version,
                      metric_weights = metric_weights)
  
  output$auth_output <- renderPrint({
    reactiveValuesToList(res_auth)
  })
}
