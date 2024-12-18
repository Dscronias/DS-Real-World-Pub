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

# Data #########################################################################
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

# User inteface ################################################################
ui <- page_navbar(
  title = "TITLE (REPLACE IT)", # Title here
  
  # Your pages
  ## PAGE 1
  nav_panel(
    title = "Welcome",
    h1("That's a title (H1)"),
    h2("That's another title, but less important (H2)"),
    p("Welcome blablablabla"),
    img(src = "image_1.jpg", height = "554px", width = "554px"),
    
    # If you want to center an image, put it in a div (it's an HTML thing, also a meme):
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
  
  ## PAGE 2
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
  
  ## PAGE 2
  nav_panel(
    title = "Page 3",
    dataTableOutput(outputId = "table_2")
  ),
  
  ## PAGE 3
  nav_panel(
    title = "Page 4"
  ),
  
  # Space in header
  nav_spacer(),
  
  # Stuff on the right
  # nav_item(input_dark_mode()), # Dark mode, doesn't work well with every theme
  nav_menu(
    title = "Links"
  ),
  
  # Sidebar
  # This will be common to all pages
  # You can make individual sidebars for each page but it is more complicated
  sidebar = sidebar(
    "Put stuff here",
    sliderInput(
      "slider_1",
      "It's a slider",
      min = 1, max = 100,
      value = c(1, 100)
    ),
    open = "closed"
  ),
  
  # Options
  theme = bs_theme(
    # See: https://rstudio.github.io/bslib/articles/theming/index.html
    bootswatch = "zephyr" # List of themes: https://bootswatch.com/
  ),
)


# Server #######################################################################
server <- function(input, output) {
  
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
  
  ## Tables ####################################################################
  output$table_1 <- renderDT({
    df
  })
  
  output$table_2 <- renderDT({
    df2_reactive()
  })
  
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
}

# Run the application 
shinyApp(ui = ui, server = server)
