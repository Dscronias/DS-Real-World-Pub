#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(bslib)
library(tidyverse)
library(DT)
library(plotly)
library(bsicons)
library(broom)
library(marginaleffects)
library(DALEX)

# Data exercise ################################################################

# Setup
df_es <-
  read_rds("final_dataframe.v3.rds") %>% 
  mutate(
    los_8h =
      case_when(
        los >= 480 ~ "Yes",
        los < 480 ~ "No"
      ) %>%
      as_factor(),
    severity = as.numeric(severity),
    ald = case_when(ald == 0 ~ "No", .default = "Yes"),
    arrival_mode_sas = case_when(
      arrival_mode == "Personal" & sas == "Yes" ~ "Personal (SAS)",
      arrival_mode == "Personal" & sas == "No" ~ "Personal (not SAS)",
      .default = arrival_mode
    ),
    arrival_mode_sas = fct_relevel(arrival_mode_sas, "Personal (SAS)"),
    discharge_mode = fct_relevel(discharge_mode, "Home")
  )

# Logistic regression
res_logit <- 
  glm(
    los_8h ~ service_code + discharge_mode + arrival_mode_sas + age + complexity + ald,
    family = "binomial",
    data = df_es
  )

# Odds ratios
res_logit_or <- tidy(res_logit, exponentiate = TRUE, conf.int = TRUE)

# Risk ratios
res_logit_rr <- avg_comparisons(res_logit, comparison = "lnratioavg", transform = exp)

# Data example #################################################################

df <- 
  tibble(
    x = rnorm(50000),
    y = runif(50000),
    z = sample(c("Red", "Blue"), 50000, replace = TRUE, prob = c(0.5, 0.5))
  )

df2 <- 
  tibble(
    x = 1:100
  )

df3 <- 
  tibble(
    dpt = c("Ain", "Aisne", "Allier", "Basses-Alpes"),
    region = c("Auverge-Rhône-Alpes", "Hauts-de-France", "Auverge-Rhône-Alpes", "Provence-Alpes-Côte d'Azur")
  )

df4 <- 
  tibble(
    x = rnorm(500, 2, 10),
    y = rnorm(500, 1, 1.5),
    z = rnorm(500, 5, 6),
    team = sample(c("Red", "Blue"), 500, replace = TRUE, prob = c(0.25, 0.75)),
    names = randomNames::randomNames(500)
  )

# User inteface ################################################################
ui <- page_navbar(
  title = "TITLE (REPLACE IT)", # Title here
  
  # Your pages
  ## PAGE 1 -----------
  nav_panel(
    title = "Welcome",
    h1("That's a title (H1)"),
    h2("That's another title, but less important (H2)"),
    p("Welcome blablablabla"),
    img(src = "image_1.jpg", height = "554px", width = "554px"),
    
    # If you want to center an image, put it in a div (it's an HTML thing, and also a meme):
    div(
      img(src = "image_1.jpg", height = "554px", width = "554px"),
      # This right below is CSS
      style = "
        display: block;
        margin-left: auto;
        margin-right: auto;
      "
    )
  ),
  
  ## PAGE 2 ---------------
  nav_panel(
    title = "Page 2",
    
    # Collection of subpages
    tabsetPanel(
      tabPanel(
        title = "Subpage 1",
        dataTableOutput(outputId = "table_1")
      ),
      tabPanel(
        title = "Subpage 2",
        plotOutput(outputId = "plot_1")
      ),
      tabPanel(
        title = "Subpage 3",
        h1("Multiple columns example"),
        layout_column_wrap(
          width = 1/2,
          plotOutput(outputId = "plot_2"),
          plotOutput(outputId = "plot_3")
        ),
        card(
          card_header("Card"),
          "That's a card"
        ),
        card(
          card_header("Another one"),
          plotlyOutput(outputId = "plot_4"),
          full_screen = TRUE
        )
      )
    )
  ),
  
  ## PAGE 3 -------------
  nav_panel(
    title = "Page 3",
    layout_columns(
      fill = FALSE,
      value_box(
        title = "Sum of X",
        value = textOutput("value_card_1"), # List here https://icons.getbootstrap.com/
        showcase = bs_icon("plus"),
        theme = "red"
      ),
      value_box(
        title = "Mean of X",
        value = textOutput("value_card_2"),
        showcase = bs_icon("calculator"),
        theme = value_box_theme(bg = "#ffbbbb", fg = "#FF0000")
      )
    ),
    dataTableOutput(outputId = "table_2")
  ),
  
  ## PAGE 4 -------------
  nav_panel(
    title = "Page 4",
    plotlyOutput(outputId = "plot_3d")
  ),
  
  # Space in header
  nav_spacer(),
  
  ## Stuff on the right --------------
  # nav_item(input_dark_mode()), # Dark mode, doesn't work well with every theme
  nav_menu(
    title = "Links",
    # align = "right", # Uncomment this and see the difference
    nav_item(
      tags$a(
        bs_icon("github"), "Github", href = "https://github.com/Dscronias/DS-Real-World-Pub/"
      )
    )
  ),
  
  ## Sidebar -------------------
  # This will be common to all pages
  # You can make individual sidebars for each page but it is more complicated
  sidebar = sidebar(
    "Put stuff here",
    
    # Slider
    sliderInput(
      inputId = "slider_1", # This is the id of your slider
      label = "It's a slider", # Title
      min = 1, max = 100,
      value = c(1, 100)
    ),
    
    # Choice boxes
    selectInput(
      "input_region",
      "Région",
      choices = c("All", sort(unique(df3$region))),
      multiple = FALSE,
      selected = "All"
    ),
    selectInput(
      "input_dpt",
      "Département",
      choices = c(sort(unique(df3$dpt))),
      multiple = TRUE
    ),
    
    open = "closed" # This means the sidebar is closer when you open the app
  ),
  
  # Options
  theme = bs_theme(
    # See: https://rstudio.github.io/bslib/articles/theming/index.html
    # This is where you ca customise the appearance of your app
    # Big modificatios will require you to know about CSS
    bootswatch = "zephyr" # List of themes: https://bootswatch.com/
  ),
)


# Server #######################################################################
server <- function(input, output, session) {
  
  ## Themer ####################################################################
  # Uncomment the next line if you want to look at different themes for your app
  # bs_themer()
  
  ## Reactive objects ##########################################################
  
  # Reactive objects get automatically modified depending on the input you defined in the UI part
  # So, here, if we want to show df2, we won't call df2, but df2_reactive()
  df2_reactive <- reactive({
    df2 %>% 
      filter(
        x >= input$slider_1[1] & # input$slider_1 is a vector of size 2 (since it is a range)
        x <= input$slider_1[2]
      )
  })
  
  ## Dynamic inputs ############################################################
  # Let's say you want one of your input/slider/text box to depend on the values of another input
  # You need to tell explicitly tell Shiny that it must actively observe this input, and change it depending on the other input
  
  # This automatically updates departement depending on region selected
  observe({
    updateSelectInput(
      session, # Leave this line as is
      "input_dpt", # Here, specify the name of the input that gets updated
      choices = df3 %>% filter(region == input$input_region) %>% pull(dpt) %>% unique() # Specify the new vector of choices for this input
      # Here, in the filter, we filter according to which region we chose in the input called "input_region"
    )
  })
  
  ## Tables ####################################################################
  output$table_1 <- renderDT({
    df
  })
  
  output$table_2 <- renderDT({
    df2_reactive()
  })
  
  ## Value cards ###############################################################
  
  output$value_card_1 <- renderText(
    df2_reactive() %>% 
      summarise(x = sum(x)) %>%
      pull(x)
  )
  
  output$value_card_2 <- renderText(
    df2_reactive() %>% 
      summarise(x = mean(x)) %>%
      pull(x)
  )
  
  ## Graphs ####################################################################
  
  output$plot_1 <- renderPlot({
    df %>% 
      ggplot(
        aes(x = x, y = y)
      ) + 
      geom_point()
  })
  
  output$plot_2 <- renderPlot({
    df %>% 
      ggplot(
        aes(x = x, y = y)
      ) + 
      geom_point() + 
      theme_minimal()
  })
  
  output$plot_3 <- renderPlot({
    df %>% 
      ggplot(
        aes(x = x, y = y, colour = z)
      ) + 
      geom_point() + 
      theme_minimal()
  })
  
  output$plot_4 <- renderPlotly({
    df %>% 
      plot_ly(
        x = ~x,
        y = ~y,
        color = ~z,
        type = 'scatter',
        mode = 'markers'
      )
  })
  
  output$plot_3d <- renderPlotly({
    df4 %>% 
      plot_ly(
        x = ~x,
        y = ~y,
        z = ~z,
        color = ~team,
        text = ~names,
        hoverinfo = "names",
        colors = c("#7777FF", "#FF7777")
      ) %>% 
      add_markers()
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
