# app.R

library(shiny)
library(shinydashboard)
library(DT)
library(readr)

# Prediction function from the paper
predict_fantasy_points <- function(target_share, yprr, competition_change, qb_skill, age_30plus) {
  -43.98 + 730.17 * target_share + 47.27 * yprr +
    24.93 * competition_change + 3.31 * qb_skill - 1.57 * age_30plus
}

ui <- dashboardPage(
  dashboardHeader(title = "NFL WR Fantasy Points Predictor"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Single Prediction", tabName = "single", icon = icon("user")),
      menuItem("Batch Prediction (CSV)", tabName = "batch", icon = icon("table")),
      menuItem("About / How To", tabName = "about", icon = icon("info-circle"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .box { font-size: 16px; }
        .value-box { color: #222; }
      "))
    ),
    tabItems(
      # SINGLE PREDICTION TAB
      tabItem(tabName = "single",
              fluidRow(
                box(title = "Input Receiver Data", width = 4, solidHeader = TRUE, status = "primary",
                    numericInput("target_share", "Target Share (0–1)", 0.20, 0, 1, 0.01),
                    numericInput("yprr", "Yards Per Route Run", 1.5, 0, 5, 0.01),
                    selectInput("competition_change", "Competition Change",
                                c("Less competition (1 – moved up depth chart/gained opportunity)" = 1,
                                  "No significant change (0 – role stable)" = 0,
                                  "More competition (-1 – moved down depth chart/lost opportunity)" = -1)),
                    selectInput("qb_skill", "Quarterback Skill",
                                c("High-quality/elite QB (1)" = 1,
                                  "Neutral or rookie QB (0)" = 0,
                                  "Low-skill QB (-1)" = -1)),
                    selectInput("age_30plus", "Age",
                                c("Under 30 years old (0)" = 0,
                                  "30 years old or older (-1)" = -1)),
                    actionButton("predict", "Predict", icon = icon("calculator")),
                    br(), br(),
                    helpText("Enter each value using the coding below (see 'About / How To' tab for a full guide).")
                ),
                valueBoxOutput("pred_box", width = 8)
              ),
              fluidRow(
                box(title="Coefficient Reference", status="info", width=12,
                    "Model: Fantasy Points = -43.98 + 730.17 * target_share + 47.27 * yprr + 24.93 * competition_change + 3.31 * qb_skill - 1.57 * age_30plus"
                )
              )
      ),
      
      # BATCH CSV TAB
      tabItem(tabName = "batch",
              fluidRow(
                box(title = "Batch CSV Upload", width = 4, solidHeader = TRUE, status = "info",
                    fileInput("csv_file", "Upload CSV", accept = ".csv"),
                    actionButton("batch_predict", "Predict Batch", icon = icon("cogs")),
                    br(), br(),
                    helpText("CSV columns required: player_name, target_share, yprr, competition_change, qb_skill, age_30plus"),
                    helpText("Each line = 1 WR. Column names MUST match exactly. See 'About / How To' tab for variable details.")
                ),
                box(title = "Batch Prediction Results", width = 8, solidHeader = TRUE, status = "success",
                    DTOutput("batch_output"),
                    br(),
                    plotOutput("points_plot", height = "250px")
                )
              )
      ),
      
      # ABOUT / HOW TO TAB
      tabItem(tabName = "about",
              fluidRow(
                box(title = "Model Overview & Instructions", width = 12, solidHeader = TRUE, status = "primary",
                    p("This app predicts next-season NFL wide receiver (WR) fantasy points using an OLS regression model developed by Ethan He (2025). You can enter a WR's data manually or upload a CSV for multiple players."),
                    h4("Variable Coding (for all features):"),
                    tags$ul(
                      tags$li(strong("target_share: "), " (Numeric, 0–1) — Proportion of team passing targets the WR earned (e.g., 0.20 for 20%)"),
                      tags$li(strong("yprr: "), " (Numeric) — Yards per route run (e.g., 1.75)"),
                      tags$li(strong("competition_change: "), " (Integer, categorical) — Encodes changes in expected target competition:",
                              tags$ul(
                                tags$li("1 = Less competition (moved up the depth chart, gained opportunity; e.g., became WR2 from WR3)"),
                                tags$li("0 = No significant change (role is stable)"),
                                tags$li("-1 = More competition (moved down the depth chart, lost opportunity; e.g., became WR3 from WR2)")
                              )
                      ),
                      tags$li(strong("qb_skill: "), " (Integer, categorical) — Quality of projected starting QB for target year:",
                              tags$ul(
                                tags$li("1 = High-quality/elite QB"),
                                tags$li("0 = Neutral or rookie QB"),
                                tags$li("-1 = Low-skill/poor QB")
                              )
                      ),
                      tags$li(strong("age_30plus: "), " (Integer, categorical) — WR age at the start of prediction year:",
                              tags$ul(
                                tags$li("0 = Under 30 years old"),
                                tags$li("-1 = 30 years old or older")
                              )
                      )
                    ),
                    h4("Sample (CSV) Required Columns:"),
                    p("player_name, target_share, yprr, competition_change, qb_skill, age_30plus"),
                    h4("About the Model"),
                    code("Fantasy Points = -43.98 + 730.17 * target_share + 47.27 * yprr + 24.93 * competition_change + 3.31 * qb_skill - 1.57 * age_30plus"),
                    br(), br(),
                    p("For further detail, see: 'Statistical Modeling of NFL Wide Receiver Fantasy Performance' by Ethan He (2025)."),
                    tags$hr(),
                    h4("Why are some variables negative?"),
                    p("The model codes certain disadvantageous situations as negative for prediction. For example, age_30plus = -1 for players 30 or older, and competition_change = -1 for players who face more competition for targets; both typically reduce projections.")
                )
              )
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Single prediction (manual input)
  observeEvent(input$predict, {
    pred <- predict_fantasy_points(
      as.numeric(input$target_share),
      as.numeric(input$yprr),
      as.numeric(input$competition_change),
      as.numeric(input$qb_skill),
      as.numeric(input$age_30plus)
    )
    output$pred_box <- renderValueBox({
      valueBox(
        sprintf("%.1f", pred),
        "Predicted Fantasy Points",
        icon = icon("football-ball"),
        color = "green"
      )
    })
  })
  
  # Batch prediction
  batch_data <- eventReactive(input$batch_predict, {
    req(input$csv_file)
    dat <- read_csv(input$csv_file$datapath, show_col_types = FALSE)
    # Check for required columns
    required_cols <- c("target_share", "yprr", "competition_change", "qb_skill", "age_30plus")
    missing_cols <- setdiff(required_cols, names(dat))
    if(length(missing_cols) > 0) {
      showNotification(paste("Missing columns:", paste(missing_cols, collapse=", ")), type="error")
      return(NULL)
    }
    dat$predicted_points <- with(dat, predict_fantasy_points(
      target_share, yprr, competition_change, qb_skill, age_30plus
    ))
    dat
  })
  
  output$batch_output <- renderDT({
    df <- batch_data()
    req(df)
    datatable(
      df,
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    ) %>% formatRound('predicted_points', 1)
  })
  
  output$points_plot <- renderPlot({
    df <- batch_data()
    req(df)
    labels <- if("player_name" %in% names(df)) df$player_name else seq_len(nrow(df))
    barplot(
      df$predicted_points,
      names.arg = labels,
      las = 2, col = "skyblue",
      main = "Predicted Fantasy Points by Player",
      ylab = "Points"
    )
  })
}

shinyApp(ui, server)



