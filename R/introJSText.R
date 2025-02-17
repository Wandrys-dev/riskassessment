# -----------------------------------------------------------------------------
# ------------ INTROJS TEXT
# -----------------------------------------------------------------------------

# Sidebar metrics.
sidebar_steps <-
  data.frame(
    element = c(
      "#assessment-criteria-tab","#database-tab",
      "#sidebar-select_pkg_ui", # "#sidebar-select_ver", # not working
      "#sidebar-status-wp", "#sidebar-score-wp",
      "#sidebar-decision-grp",
      "#sidebar-overall-comment-grp"),
    intro = c(
      "Discover the package assessment process & criteria",
      "Review the R packages that already exist in the database",
      "Expand this dropdown list to selet assess a specific package that was previously uploaded. Then select a version (if more than one exists).",
      # "The latest version will autopopulate here.", # can't peg ui object name, even with a div!
      "The status can be either 'Under Review' or 'Reviewed'.",
      "The score can take any value between 0 (no risk) and 1 (highest risk).",
      "After reviewing your package, you can leave an overall comment.",
      "Provide your input on the overall risk of the selected package."
    ),
    position = c(rep("bottom", 7))
  )

# upload package tab.
upload_pkg <- data.frame(
  element = c("#upload_package-introJS-help", "#upload-file-grp", "#upload_package-upload_format"),
  intro = c(
    "Click here anytime you need help.",
    "Upload a CSV file with the package(s) you would like to assess.",
    "You can use this sample dataset to explore the app."
  ),
  position = c("right", rep("top", 2))
)

upload_pkg_complete <- union(upload_pkg,
    data.frame(
      element = c("#upload_summary_div", "#upload_package-upload_pkgs_table"),
      intro = c(
        "Text description of packages uploaded. Counts by type: 'Total', 'New', 'Undiscovered', 'Duplicate'.",
        "Confirm uploaded packages list, filter by type"
      ),
      position = c("bottom", "top")
    )
#     # } else {
#     #   data.frame(element = character(0) , intro = character(0), position = character(0))
#     # }
  )


# Maintenance metrics.
mm_steps <- 
  data.frame(
    element = c(".card-group", "#comments_for_mm"),
    intro = c(
      "Several ways to measuring package maintenance are assessed here. Please review each!",
      "Have something to share within your organization? Add a comment and keep track of the on-going conversation for this package's maintainence metrics"
    ),
    position = c(rep("left", 2))
  )


# Report Preview.
rp_steps <- data.frame(
  element = c( "#dwnld_rp", "#rep_prev"),
  intro = c(
    "Select file output type for report seen below and download for later use",
    "The current assessment of this package including your comments and overall decision have been collected from the other tabs to prepare the following report for convenience."
  ),
  position = c("left", "left")
)


# Community Usage Metrics.
cum_steps <- data.frame(
  element = c("#cum_infoboxes", "#cum_plot", "#comments_for_cum"),
  intro = c(
    "Several ways of measuring community usage are assessed here. Please review each!",
    "Digest the 'downloads per month' metric by selecting a pre-defined time periods or toggling the date slider at bottom of plot for custom date range",
    "Have something to share within your organization? Add a comment and keep track of the on-going conversation for this package's community usage metrics"
  ),
  position = c(rep("left", 3))
  
)


