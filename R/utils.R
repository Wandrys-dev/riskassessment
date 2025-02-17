
#' The 'Add tags' function
#' 
#' @param ui placeholder
#' @param ... placeholder
#' 
#' @import shiny
#' @importFrom shinymanager fab_button
#' @importFrom shinyjs useShinyjs
add_tags <- function(ui, ...) {
  ui <- force(ui)
  
  function(request) {
    query <- parseQueryString(request$QUERY_STRING)
    admin <- query$admin
    
    if (is.function(ui)) {
      ui <- ui(request)
    }
    
    if (identical(admin, "true")) {
      ui <- tagList(ui, 
                    tags$script(HTML("document.getElementById('admin-add_user').style.width = 'auto';")),
                    tags$script(HTML("var oldfab = Array.prototype.slice.call(document.getElementsByClassName('mfb-component--br'), 0);
                             for (var i = 0; i < oldfab.length; ++i) {
                               oldfab[i].remove();
                             }")),
                    shinymanager::fab_button(
                      position = "bottom-right",
                      actionButton(
                        inputId = ".shinymanager_logout",
                        label = "Logout",
                        icon = icon("right-from-bracket")
                      ),
                      actionButton(
                        inputId = ".shinymanager_app",
                        label = "Go to application",
                        icon = icon("share")
                      )
                    )
      )
    }
    
    tagList(shinyjs::useShinyjs(),
            ui,
            tags$script(HTML("$(document).on('shiny:value', function(event) {
                             if (event.target.id === 'admin-table_users') {
                             Shiny.onInputChange('table_users-returns', document.getElementById('admin-table_users').innerHTML)
                             } else if (event.target.id === 'admin-table_pwds') {
                             Shiny.onInputChange('table_pwds-returns', document.getElementById('admin-table_pwds').innerHTML)
                             }
                             });")))
  }
}



#' Create package database
#' 
#' @description Note: the database_name object is assigned in data-raw/internal-data.R
#' 
#' @param db_name a string
#' 
#' @import dplyr
#' @importFrom DBI dbConnect dbDisconnect dbSendStatement dbClearResult
#' @importFrom RSQLite SQLite
#' @importFrom loggit loggit
#' 
create_db <- function(db_name = database_name){
  
  # Create an empty database.
  con <- DBI::dbConnect(RSQLite::SQLite(), db_name)
  
  # Set the path to the queries.
  path <- app_sys("app/www/sql_queries") #file.path('sql_queries')
  
  # Queries needed to run the first time the db is created.
  queries <- c(
    "create_package_table.sql",
    "create_metric_table.sql",
    "initialize_metric_table.sql",
    "create_package_metrics_table.sql",
    "create_community_usage_metrics_table.sql",
    "create_comments_table.sql"
  )
  
  # Append path to the queries.
  queries <- file.path(path, queries)
  
  # Apply each query.
  sapply(queries, function(x){
    
    tryCatch({
      rs <- DBI::dbSendStatement(
        con,
        paste(scan(x, sep = "\n", what = "character"), collapse = ""))
    }, error = function(err) {
      message <- paste("dbSendStatement",err)
      message(message, .loggit = FALSE)
      loggit::loggit("ERROR", message)
      DBI::dbDisconnect(con)
    })
    
    DBI::dbClearResult(rs)
  })
  
  DBI::dbDisconnect(con)
}



#' Create credentials database
#' 
#' Note: the credentials_name object is assigned in data-raw/internal-data.R
#' 
#' @param db_name a string
#' 
#' @import dplyr
#' @importFrom DBI dbConnect dbDisconnect
#' @importFrom RSQLite SQLite
#' @importFrom shinymanager read_db_decrypt write_db_encrypt
#' 
create_credentials_db <- function(db_name = credentials_name){
  
  # Init the credentials table for credentials database
  credentials <- data.frame(
    user = "admin",
    password = "QWERTY1",
    # password will automatically be hashed
    admin = TRUE,
    expire = as.character(Sys.Date()),
    stringsAsFactors = FALSE
  )
  
  # Init the credentials database
  shinymanager::create_db(
    credentials_data = credentials,
    sqlite_path = file.path(db_name), 
    passphrase = passphrase
  )
  
  # set pwd_mngt$must_change to TRUE
  con <- DBI::dbConnect(RSQLite::SQLite(), db_name)
  pwd <- shinymanager::read_db_decrypt(
    con, name = "pwd_mngt",
    passphrase = passphrase) %>%
    dplyr::mutate(must_change = ifelse(
      have_changed == "TRUE", must_change, as.character(TRUE)))
  
  shinymanager::write_db_encrypt(
    con,
    value = pwd,
    name = "pwd_mngt",
    passphrase = passphrase
  )
  DBI::dbDisconnect(con)
  
  # update expire date here to current date + 365 days
  con <- DBI::dbConnect(RSQLite::SQLite(), db_name)
  dat <- shinymanager::read_db_decrypt(con, name = "credentials", passphrase = passphrase) %>%
    dplyr::mutate(expire = as.character(Sys.Date() + 365))
  
  shinymanager::write_db_encrypt(
    con,
    value = dat,
    name = "credentials",
    passphrase = passphrase
  )
  
  DBI::dbDisconnect(con)
}





#' Select data from database
#' 
#' @param query a sql query as a string
#' @param db_name a string
#' 
#' @import dplyr
#' @importFrom DBI dbConnect dbSendQuery dbFetch dbClearResult dbDisconnect
#' @importFrom RSQLite SQLite
#' @importFrom loggit loggit
dbSelect <- function(query, db_name = database_name){
  errFlag <- FALSE
  con <- DBI::dbConnect(RSQLite::SQLite(), db_name)

  tryCatch(
    expr = {
      rs <- DBI::dbSendQuery(con, query)
    },
    warning = function(warn) {
      message <- paste0("warning:\n", query, "\nresulted in\n", warn)
      message(message, .loggit = FALSE)
      loggit::loggit("WARN", message)
      errFlag <<- TRUE
    },
    error = function(err) {
      message <- paste0("error:\n", query, "\nresulted in\n",err)
      message(message, .loggit = FALSE)
      loggit::loggit("ERROR", message)
      DBI::dbDisconnect(con)
      errFlag <<- TRUE
    },
    finally = {
      if (errFlag) return(NULL) 
    })
  
  dat <- DBI::dbFetch(rs)
  DBI::dbClearResult(rs)
  DBI::dbDisconnect(con)
  
  return(dat)
}




#' dbUpdate
#'
#' Deletes, updates or inserts queries.
#'
#' @param command a string
#' @param db_name a string
#'
#' @import dplyr
#' @importFrom DBI dbConnect dbSendStatement dbClearResult dbDisconnect
#'   dbGetRowsAffected
#' @importFrom RSQLite SQLite
#' @importFrom loggit loggit
#' @importFrom glue glue
dbUpdate <- function(command, db_name = database_name){
  con <- DBI::dbConnect(RSQLite::SQLite(), db_name)
  
  tryCatch({
    rs <- DBI::dbSendStatement(con, command)
  }, error = function(err) {
    message <- glue::glue("command: {command} resulted in {err}")
    message(message, .loggit = FALSE)
    loggit::loggit("ERROR", message)
    DBI::dbDisconnect(con)
  })
  
  nr <- DBI::dbGetRowsAffected(rs)
  DBI::dbClearResult(rs)
  
  if (nr == 0) {
    message <- glue::glue("zero rows were affected by the command: {command}")
    message(message, .loggit = FALSE)
  }
  DBI::dbDisconnect(con)
}


#' getTimeStamp
#'
#' Retrieves Sys.time(), but transforms slightly
#'
#' @importFrom stringr str_replace
getTimeStamp <- function(){
  initial <- stringr::str_replace(Sys.time(), " ", "; ")
  return(paste(initial, Sys.timezone()))
}


#' get_metric_weights
#'
#' Retrieves metric name and current weight from metric table
#'
get_metric_weights <- function(){
  dbSelect(
    "SELECT name, weight
     FROM metric"
  )
}


#' weight_risk_comment
#'
#' Used to add a comment on every tab saying how the risk and weights changed,
#' and that the overall comment & final decision may no longer be applicable.
#' 
#' @param pkg_name a package name, as a string
#' @importFrom glue glue
weight_risk_comment <- function(pkg_name) {
  
  pkg_score <- dbSelect(glue::glue(
    "SELECT score
     FROM package
     WHERE name = '{pkg_name}'"
  ))
  
  glue::glue('Metric re-weighting has occurred.
       The previous risk score was {pkg_score}.')
}

#' update_metric_weight
#' 
#' @param metric_name a metric name, as a string
#' @param metric_name a weight, as a string or double
#' 
#' @importFrom glue glue
update_metric_weight <- function(metric_name, metric_weight){
  dbUpdate(glue::glue(
    "UPDATE metric
    SET weight = {metric_weight}
    WHERE name = '{metric_name}'"
  ))
}

#' The 'Get Date Span' function
#' 
#' Function accepts a start date and optional end date and will 
#' 
#' @param start starting date
#' @param end ending date
#' 
#' @importFrom lubridate interval years
#' @importFrom stringr str_remove
#' 
get_date_span <- function(start, end = Sys.Date()) {
  # Get approximate difference between today and latest release.
  # time_diff_latest_version <- lubridate::year(Sys.Date()) - last_ver$year
  time_diff <- lubridate::interval(start, end)
  time_diff_val <- time_diff %/% months(1)
  time_diff_label <- 'Months'
  
  if(time_diff_val >= 12) {
    # Get difference in months.
    time_diff_val <- time_diff %/% lubridate::years(1)
    time_diff_label <- 'Years'
  }
  # remove "s" off of "Years" or "Months" if 1
  if(time_diff_val == 1)
    time_diff_label <- stringr::str_remove(
      string = time_diff_label, pattern = 's$')
  return(list(value = time_diff_val, label = time_diff_label))
}

#' The 'Build Community Cards' function
#' 
#' @param data a data.frame
#' 
#' @import dplyr
#' @importFrom lubridate interval make_date year
#' @importFrom glue glue
#' @importFrom tibble add_row
#' 
build_comm_cards <- function(data){

  # Get the first package release.
  first_version <- data %>%
    dplyr::filter(year == min(year)) %>%
    dplyr::filter(month == min(month)) %>%
    dplyr::slice_head(n = 1) %>%
    dplyr::mutate(fake_rel_date = lubridate::make_date(year, month, 15))
  
  # get the time span in months or years depending on how much time
  # has elapsed
  time_diff_first_rel <- get_date_span(first_version$fake_rel_date)
  
  cards <- data.frame(
    name = 'time_since_first_version',
    title = 'First Version Release',
    desc = 'Time passed since first version release',
    value = glue::glue('{time_diff_first_rel$value} {time_diff_first_rel$label} Ago'),
    succ_icon = 'black-tie',
    icon_class = "text-info",
    is_perc = 0,
    is_url = 0
  )
  
  
  # Get the last package release's month and year, then
  # make add in the release date
  last_ver <- data %>%
    dplyr::filter(!(version %in% c('', 'NA'))) %>%
    dplyr::filter(year == max(year)) %>%
    dplyr::filter(month == max(month)) %>%
    dplyr::slice_head(n = 1) %>%
    dplyr::mutate(fake_rel_date = lubridate::make_date(year, month, 15))
  
  # get the time span in months or years depending on how much time
  # has elapsed
  time_diff_latest_rel <- get_date_span(last_ver$fake_rel_date)
  
  cards <- cards %>%
    tibble::add_row(name = 'time_since_latest_version',
            title = 'Latest Version Release',
            desc = 'Time passed since latest version release',
            value = glue::glue('{time_diff_latest_rel$value} {time_diff_latest_rel$label} Ago'),
            succ_icon = 'meteor',
            icon_class = "text-info",
            is_perc = 0,
            is_url = 0)
  
  downloads_last_year <- data %>%
    dplyr::filter(year == lubridate::year(Sys.Date()) - 1) %>%
    dplyr::distinct(year, month, downloads)
  
  cards <- cards %>%
    tibble::add_row(name = 'downloads_last_year',
            title = 'Package Downloads',
            desc = 'Number of downloads since last year',
            value = format(sum(downloads_last_year$downloads), big.mark = ","),
            succ_icon = 'box-open',
            icon_class = "text-info",
            is_perc = 0,
            is_url = 0)
  
  cards
}



#' The 'Build Community plot' function
#' 
#' @param data a data.frame
#' 
#' @import dplyr
#' @importFrom lubridate NA_Date_ interval
#' @importFrom glue glue
#' @importFrom plotly plot_ly layout add_segments add_annotations config
#' 
build_comm_plotly <- function(data) {
  if (nrow(data) == 0) return(NULL)
  
  pkg_name <- unique(data$id)
  
  community_data <- data %>%
    dplyr::mutate(day_month_year = glue::glue('1-{month}-{year}')) %>%
    dplyr::mutate(day_month_year = as.Date(day_month_year, "%d-%m-%Y")) %>%
    dplyr::mutate(month_year = glue::glue('{months(day_month_year)} {year}')) %>%
    dplyr::mutate(month = month.name[month]) %>%
    dplyr::arrange(day_month_year)
  
  downloads_data <- community_data %>%
    dplyr::distinct(month, year, .keep_all = TRUE)
  
  # Last day that appears on the community metrics.
  latest_date <- downloads_data %>%
    dplyr::slice_max(day_month_year) %>%
    dplyr::pull(day_month_year)
  
  # Last day associated with a version release.
  last_version_date <- downloads_data %>%
    dplyr::filter(!(version %in% c('', 'NA'))) %>%
    dplyr::slice_max(day_month_year) %>%
    dplyr::pull(day_month_year)
  
  # First day associated with a version release.
  first_version_date <- downloads_data %>%
    dplyr::filter(!(version %in% c('', 'NA'))) %>%
    dplyr::slice_min(day_month_year) %>%
    dplyr::pull(day_month_year)
  
  # Get the difference in months.
  month_last <- lubridate::interval(last_version_date, latest_date) %/% months(1)
  month_first <- lubridate::interval(first_version_date, latest_date) %/% months(1)
  
  # Set plot range: [min - 15 days, max + 15 days].
  # Dates need to be transformed to milliseconds since epoch.
  dates_range <- c(
    (as.numeric(min(downloads_data$day_month_year)) - 15) * 86400000,
    (as.numeric(max(downloads_data$day_month_year)) + 15) * 86400000)
  
  # set default at 2 years
  default_range <- c(
    max(downloads_data$day_month_year) - 45 - (365 * 2),
    max(downloads_data$day_month_year) + 15)
  
  plotly::plot_ly(downloads_data,
          x = ~day_month_year,
          y = ~downloads,
          name = "# Downloads", type = 'scatter', 
          mode = 'lines+markers', line = list(color = '#1F9BCF'),
          marker = list(color = '#1F9BCF'),
          hoverinfo = "text",
          text = ~glue::glue('No. of Downloads: {format(downloads, big.mark = ",")}
                         {month} {year}')) %>%
    plotly::layout(title = glue::glue('NUMBER OF DOWNLOADS BY MONTH: {pkg_name}'),
           margin = list(t = 100),
           showlegend = FALSE,
           yaxis = list(title = "Downloads"),
           xaxis = list(title = "", type = 'date', tickformat = "%b %Y",
                        range = dates_range)
    ) %>% 
    plotly::add_segments(
      x = ~dplyr::if_else(version %in% c("", "NA"), lubridate::NA_Date_, day_month_year),
      xend = ~dplyr::if_else(version %in% c("", "NA"), lubridate::NA_Date_, day_month_year),
      y = ~.98 * min(downloads),
      yend = ~1.02 * max(downloads),
      name = "Version Release",
      hoverinfo = "text",
      text = ~glue::glue('Version {version}'),
      line = list(color = '#4BBF73')
    ) %>% 
    plotly::add_annotations( 
      yref = 'paper',
      xref = "x",
      y = .50,
      x = downloads_data$day_month_year,
      xanchor = 'left',
      showarrow = F,
      textangle = 270,
      font = list(size = 14, color = '#4BBF73'),
      text = ~ifelse(downloads_data$version %in% c("", "NA"), "", downloads_data$version)
    ) %>%
    plotly::layout(
      xaxis = list(
        range = dates_range,
        rangeselector = list(
          buttons = list(
            list(count = month_first + 1,
                 label = "First Release",
                 step = "month",
                 stepmode = "todate"),
            list(count = month_last + 1,
                 label = "Last Release",
                 step = "month",
                 stepmode = "backward"),
            list(
              count = 24 + 1,
              label = "2 yr",
              step = "month",
              stepmode = "backward"),
            list(
              count = 12 + 1,
              label = "1 yr",
              step = "month",
              stepmode = "backward"),
            list(
              count = 6 + 1,
              label = "6 mo",
              step = "month",
              stepmode = "backward")
          )),
        rangeslider = list(visible = TRUE)
      )
    ) %>%
    plotly::config(displayModeBar = F)
}









# Below are a series of get_* functions that help us query
# certain sql tables in a certain way. They are used 2 - 3
# times throughout the app, so it's best to maintain them
# in a central location

#' The 'Get Overall Comments' function
#' 
#' Retrieves the overall comments for a specific package
#' 
#' @param pkg_name string
#' 
#' @importFrom glue glue
#' 
get_overall_comments <- function(pkg_name) {
  dbSelect(glue::glue(
    "SELECT * FROM comments 
     WHERE comment_type = 'o' AND id = '{pkg_name}'")
  )
}

#' The 'Get Maintenance Metrics Comments' function
#' 
#' Retrieves the Maint Metrics comments for a specific package
#' 
#' @param pkg_name string
#' 
#' @importFrom glue glue
#' @importFrom purrr map
#' 
get_mm_comments <- function(pkg_name) {
  dbSelect(
    glue::glue(
      "SELECT user_name, user_role, comment, added_on
       FROM comments
       WHERE id = '{pkg_name}' AND comment_type = 'mm'"
    )
  ) %>%
    purrr::map(rev)
}

#' The 'Get Community Usage Metrics Comments' function
#' 
#' Retrieve the Community Metrics comments for a specific package
#' 
#' @param pkg_name string
#' 
#' @importFrom glue glue
#' @importFrom purrr map
#' 
get_cm_comments <- function(pkg_name) {
  dbSelect(
    glue::glue(
      "SELECT user_name, user_role, comment, added_on
       FROM comments
       WHERE id = '{pkg_name}' AND comment_type = 'cum'"
    )
  ) %>%
    purrr::map(rev)
}

#' The 'Get Maintenance Metrics Data' function
#' 
#' Pull the maint metrics data for a specific package id, and create 
#' necessary columns for Cards UI
#' 
#' @param pkg_id string
#' 
#' @import dplyr
#' @importFrom glue glue
#' 
get_mm_data <- function(pkg_id){
  dbSelect(glue::glue(
    "SELECT metric.name, metric.long_name, metric.description, metric.is_perc,
                    metric.is_url, package_metrics.value
                    FROM metric
                    INNER JOIN package_metrics ON metric.id = package_metrics.metric_id
                    WHERE package_metrics.package_id = '{pkg_id}' AND 
                    metric.class = 'maintenance' ;")) %>%
    dplyr::mutate(
      title = long_name,
      desc = description,
      succ_icon = rep(x = 'check', times = nrow(.)), 
      unsucc_icon = rep(x = 'times', times = nrow(.)),
      icon_class = rep(x = 'text-success', times = nrow(.)),
      .keep = 'unused'
    )
}


#' The 'Get Communnity Data' function
#' 
#' Get all community metric data on a specific package
#' 
#' @param pkg_name string
#' 
#' @importFrom glue glue
#' 
get_comm_data <- function(pkg_name){
  dbSelect(glue::glue(
    "SELECT *
     FROM community_usage_metrics
     WHERE id = '{pkg_name}'")
  )
}

#' The 'Get Package Info' function
#' 
#' Get all general info on a specific package
#' 
#' @param pkg_name string
#' 
#' @importFrom glue glue
#' 
get_pkg_info <- function(pkg_name){
  dbSelect(glue::glue(
    "SELECT *
     FROM package
     WHERE name = '{pkg_name}'")
    )
}

##### End of get_* functions #####
