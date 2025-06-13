# Title: Automated Plot Summary and Metadata Extraction using Azure OpenAI
#
# Description:
# This script defines a workflow to extract summaries and metadata (title, axes, legend)
# from a given plot using Azure OpenAI services. It configures Azure credentials,
# defines a chat function for authentication and API calls, and provides a main
# function (`chat_azure_core_plot`) to analyze a plot and return structured information.
#
# Main Steps:
# 1. Load required R libraries for API interaction and data manipulation.
# 2. Set up Azure OpenAI and Microsoft authentication using environment variables.
# 3. Define a function (`chat_azure_core`) to obtain an access token and interact
#    with Azure OpenAI for analysis.
# 4. Specify a structured prompt (`type_summary`) for the LLM to extract plot metadata.
# 5. Use the main function (`chat_azure_core_plot`) to process a plot and return
#    the requested information (title, axes, legend, summary, or all).
# 6. Example usage: Summarize a bar plot of average claim amounts by region and status.
#
# Output:
# - Returns a list or string containing the plot's title, axes descriptions, legend,
#   and summary, depending on the `output_type` argument.
#
# Notes:
# - Ensure all Azure credentials and deployment details are correctly set in
#   environment variables before running.
# - The script assumes the use of the 'ellmer' package and a compatible Azure OpenAI deployment.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# 1. Load Required Libraries
# ------------------------------------------------------------------------------
library(ellmer)
library(httr)
library(rtiktoken)
library(dplyr)
library(ggplot2)

# ------------------------------------------------------------------------------
# 2. Set Environment Variables for Azure OpenAI
# ------------------------------------------------------------------------------
Sys.setenv(AZURE_OPENAI_ENDPOINT = "input yours")
Sys.setenv(HI_APIM_APP_ID = "input yours")
Sys.setenv(AZURE_TENANT_ID = "input yours")
Sys.setenv(AZURE_CLIENT_ID = "input yours")
Sys.setenv(AZURE_CLIENT_SECRET = "input yours")
Sys.setenv(AZURE_SUBSCRIPTION_ID = "input yours")

# ------------------------------------------------------------------------------
# 3. Azure OpenAI Chat Function
# ------------------------------------------------------------------------------
# Authenticates with Azure and sends a prompt to the OpenAI endpoint.
chat_azure_core <- function(system_prompt) {
  endpoint <- Sys.getenv("AZURE_OPENAI_ENDPOINT")
  subscription_id <- Sys.getenv("AZURE_SUBSCRIPTION_ID")
  client_id <- Sys.getenv("AZURE_CLIENT_ID")
  client_secret <- Sys.getenv("AZURE_CLIENT_SECRET")
  tenant_id <- Sys.getenv("AZURE_TENANT_ID")
  authority <- paste0("https://login.microsoftonline.com/", tenant_id)
  token_url <- paste0(authority, "/oauth2/v2.0/token")
  scope <- paste0("api://", Sys.getenv("input yours"), "/.default")  # Update as needed
  
  api_version <- "input yours"      # Specify API version
  deployment_id <- "input yours"    # Specify deployment ID
  
  # Obtain access token
  response <- POST(
    url = token_url,
    body = list(
      grant_type = "client_credentials",
      client_id = client_id,
      client_secret = client_secret,
      scope = scope
    ),
    encode = "form"
  )
  token_response <- content(response, "parsed")
  access_token <- token_response$access_token
  
  creds <- list(
    'Authorization' = paste('Bearer', access_token),
    'Content-Type' = 'application/json'
  )
  
  # Call Azure OpenAI chat endpoint
  chat <- chat_azure_openai(
    endpoint = endpoint,
    deployment_id = deployment_id,
    api_version = api_version,
    system_prompt = system_prompt,
    api_key = subscription_id,
    credentials = creds
  )
  return(chat)
}

# ------------------------------------------------------------------------------
# 4. Prompt Design for Plot Metadata Extraction
# ------------------------------------------------------------------------------
# Defines the prompt structure for the LLM to extract plot metadata and summary.
type_summary <- function(summary_prompt) {
  type_object(
    "Summary of the plot.",
    title = type_string("Read the title of the plot. If not, give a title for the plot."),
    x_axis = type_string("Describe the x axis with detail, e.g. value, type, range."),
    y_axis = type_string("Describe the y axis with detail, e.g. value, type, range."),
    legend = type_string("Describe the legend in the plot."),
    summary = type_string(summary_prompt)
  )
}

# ------------------------------------------------------------------------------
# 5. Main Function: Analyze Plot and Return Metadata
# ------------------------------------------------------------------------------
# Analyzes a plot and returns title, axes, legend, and summary as requested.
chat_azure_core_plot <- function(
    plot,
    summary_prompt = "Summary of the plot. Pay attention to the trend and relationship. Give the rough numbers. Start with: This plot illustrates",
    output_type = "all"
) {
  # Validate output_type
  if (!output_type %in% c("all", "title", "summary", "x_axis", "y_axis", "legend")) {
    stop("Invalid output_type. Choose from 'all', 'title', 'summary', 'x_axis', 'y_axis', or 'legend'.")
  }
  
  chat <- chat_azure_core(
    system_prompt = "You are a senior data analyst"
  )
  
  type_sum <- type_summary(summary_prompt)
  data <- chat$extract_data(plot, type = type_sum)
  
  # Return based on output_type
  switch(output_type,
         title = data$title,
         x_axis = data$x_axis,
         y_axis = data$y_axis,
         legend = data$legend,
         summary = data$summary,
         all = data
  )
}

# ------------------------------------------------------------------------------
# 6. Example Usage
# ------------------------------------------------------------------------------
# Summarize a bar plot of average claim amounts by region and claim status.

# Example data
claim_data <- data.frame(
  claim_id = 1:20,
  claim_amount = c(500, 3000, 1500, 7000, 2000, 500, 6000, 1200, 3500, 6500, 1000, 8000, 2200, 4000, 12000, 3000, 4500, 2200, 6000, 7500),
  age_of_claimant = c(25, 34, 45, 52, 23, 40, 60, 70, 68, 55, 38, 29, 47, 33, 50, 41, 39, 62, 49, 58),
  claim_status = c("Approved", "Rejected", "Approved", "Approved", "Rejected", "Pending", "Approved", "Pending", "Rejected", "Approved", "Pending", "Approved", "Rejected", "Approved", "Approved", "Pending", "Rejected", "Approved", "Pending", "Approved"),
  region = c("North", "South", "East", "West", "North", "South", "East", "West", "North", "South", "East", "West", "North", "South", "East", "West", "North", "South", "East", "West")
)

# Summarize the data to get average claim amount by region and claim status
summary_data <- claim_data %>%
  group_by(region, claim_status) %>%
  summarise(average_claim_amount = mean(claim_amount), .groups = 'drop')

# Create the plot
p <- ggplot(summary_data, aes(x = region, y = average_claim_amount, fill = claim_status)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(
    title = "Average Claim Amount by Region and Claim Status",
    x = "Region",
    y = "Average Claim Amount",
    fill = "Claim Status"
  ) +
  theme_minimal()

# Convert plot to compatible format for LLM (if needed)
plot1 <- content_image_plot(p)

# Analyze the plot
chat_azure_core_plot(plot1, summary_prompt = "Summarize the plot", output_type = 'all')