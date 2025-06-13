# Title: Mental Health Sentiment Classification Pipeline using Azure OpenAI
#
# Description:
# This script implements a workflow for classifying mental health-related text 
# into sentiment categories using Azure OpenAI services. 
#
# Main Steps:
# 1. Load required R libraries for data manipulation, API interaction, and file I/O.
# 2. Import the mental health dataset from a CSV file.
# 3. Set up Azure OpenAI and Microsoft authentication using environment variables.
# 4. Define a function (`chat_azure_core`) to interact with Azure OpenAI, 
#    obtaining an access token and sending prompts for analysis.
# 5. Specify a structured prompt (`type_summary`) for the LLM to return 
#    class probabilities for each mental health category.
# 6. Loop through dataset entries, sending each text to the LLM, parsing the 
#    response, and storing results in a CSV file.
# 7. After each batch, calculate and print the proportion of correct predictions.
# 8. Continue processing until all entries are classified.
#
# Output:
# - A CSV file ("result.csv") containing the predicted probabilities and 
#   classifications for each text entry.
#
# Notes:
# - Ensure all Azure credentials and deployment details are correctly set in 
#   environment variables before running.
# - The script is designed for large-scale batch processing (up to 10,000 entries).
# - Error handling is included to skip problematic entries and continue processing.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# 1. Load Required Libraries
# ------------------------------------------------------------------------------
library(ellmer)
library(httr)
library(rtiktoken)
library(readxl)

# ------------------------------------------------------------------------------
# 2. Import Dataset
# ------------------------------------------------------------------------------
# Reads the mental health dataset from a CSV file.
textclass <- read.csv("mentalhealth.csv")

# ------------------------------------------------------------------------------
# 3. Set Environment Variables for Azure OpenAI
# ------------------------------------------------------------------------------
# Configure Azure and OpenAI credentials.
Sys.setenv(AZURE_OPENAI_ENDPOINT = "input yours")
Sys.setenv(HI_APIM_APP_ID = "input yours")
Sys.setenv(AZURE_TENANT_ID = "input yours")
Sys.setenv(AZURE_CLIENT_ID = "input yours")
Sys.setenv(AZURE_CLIENT_SECRET = "input yours")
Sys.setenv(AZURE_SUBSCRIPTION_ID = "input yours")

# ------------------------------------------------------------------------------
# 4. Azure OpenAI Chat Function
# ------------------------------------------------------------------------------
# This function authenticates with Azure and sends a prompt to the OpenAI endpoint.
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
# 5. Prompt Design for Sentiment Classification
# ------------------------------------------------------------------------------
# Defines the prompt structure for the LLM to classify mental health sentiment.
type_summary <- type_object(
  all = type_string(
    "Predict the sentiment category based on the content.

Provide class probabilities for each of the following categories: Anxiety, Bipolar, Depression, Normal, Personality Disorder, Stress, and Suicidal.

The probabilities should represent the likelihood of the text belonging to each category, summing up to 1.00.

Use the following format for output:

Anxiety: [Probability Value]
Bipolar: [Probability Value]
Depression: [Probability Value]
Normal: [Probability Value]
Personality Disorder: [Probability Value]
Stress: [Probability Value]
Suicidal: [Probability Value]

Example for final output:

Anxiety: 0.0111
Bipolar: 0.0693
Depression: 0.1111
Normal: 0.7580
Personality Disorder: 0.0073
Stress: 0.0021
Suicidal: 0.0412"
  )
)

# ------------------------------------------------------------------------------
# 6. Main Loop: Analyze Text and Save Results
# ------------------------------------------------------------------------------
# Iterates through the dataset, sends each text to the LLM, parses the response,
# and saves the results to a CSV file. Stops after 10,000 entries.

res <- data.frame()
write.csv(res, "result.csv", row.names = FALSE)

repeat {
  start_time <- Sys.time()
  res <- read_csv("result.csv")
  result_list <- list()
  
  for (i in (nrow(res) + 1):10000) {
    data1 <- tryCatch({
      chat_azure_core(
        "You are a senior analyst designed to analyze text related to mental health and provide sentiment classification."
      )$chat_structured(textclass[i, 2], type = type_summary)
    }, error = function(e) {
      message(sprintf("Error at index %d: %s", i, e$message))
      return(list("Condition: NA"))
    })
    
    lines <- unlist(strsplit(data1[[1]], "\n"))
    df <- do.call(rbind, lapply(lines, function(line) {
      parts <- unlist(strsplit(line, ": "))
      data.frame(
        order = i,
        text = textclass[i, 2],
        Condition = parts[1],
        Value = as.numeric(parts[2]),
        Flg = textclass[i, 3],
        stringsAsFactors = FALSE
      )
    }))
    result_list[[i]] <- df
  }
  
  end_time <- Sys.time()
  print(end_time - start_time)
  
  if (length(result_list) > 0) {
    final_df <- do.call(rbind, result_list)
    
    result_com2 <- final_df %>%
      group_by(order) %>%
      slice_max(order_by = Value, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      select(order, text, Condition, Value, Flg)
    
    result_all <- rbind(res, result_com2)
    write.csv(result_all, "result.csv", row.names = FALSE)
  }
  
  res <- read_csv("result.csv")
  proportion_equal <- mean(res$Condition == res$Flg, na.rm = TRUE)
  print(proportion_equal)
  
  if (nrow(res) >= 10000) break
}

















