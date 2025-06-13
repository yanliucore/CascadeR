# Title: Literature Review Extraction Pipeline using Azure OpenAI
#
# Description:
# This script automates the extraction of structured summaries from a folder of
# research articles and documents (PDF, PPTX, DOCX, MSG) using Azure OpenAI.
#
# Main Steps:
# 1. Load required R libraries for file handling, text extraction, and API calls.
# 2. Set up Azure OpenAI and Microsoft authentication using environment variables.
# 3. Define a function (`chat_liter`) to interact with Azure OpenAI for data extraction.
# 4. Specify a structured prompt (`type_summary`) for the LLM to extract article metadata.
# 5. Loop through all files in the specified folder, extract text, and call the LLM.
# 6. Combine all extracted data into a single data frame and save as CSV.
#
# Output:
# - A CSV file ("literature_review.csv") containing structured summaries for each document.
#
# Notes:
# - Ensure all Azure credentials and deployment details are correctly set in
#   environment variables before running.
# - The script supports PDF, PPTX, DOCX, and MSG file formats.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# 1. Load Required Libraries
# ------------------------------------------------------------------------------
library(purrr)
library(here)
library(pdftools)
library(officer)
library(msgxtractr)
library(Microsoft365R)
library(tidyverse)
library(readxl)

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
chat_liter <- function(system_prompt) {
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
  
  chat <- chat_azure_core(
    system_prompt = "You are a senior research scientist to evaluate the Oregon health authority waiver 1115 policy"
  )
  return(chat)
}

# ------------------------------------------------------------------------------
# 4. Prompt Design for Structured Article Summary Extraction
# ------------------------------------------------------------------------------
type_summary <- type_object(
  title    = type_string("Title of the article"),
  FirstNM  = type_string("First Name of the article's first author"),
  LastNM   = type_string("Last Name of the article's first author"),
  Pubdate  = type_string("Publication date as format month/day/year with two numbers in month and day, 4 numbers in year"),
  Journal  = type_string("Journal of the article"),
  DOI      = type_string("DOI of the article"),
  Summary  = type_string("Summary of the article, 50 words"),
  Methods  = type_string("List the names of the statistical methods used in this article"),
  Population = type_string("Population of this article")
)

# ------------------------------------------------------------------------------
# 5. Main Loop: Literature Review from Folder
# ------------------------------------------------------------------------------
# Define the folder path containing the documents
folder_path <- "input yours"

# Get a list of all files in the folder
files <- list.files(folder_path, full.names = TRUE)

# Initialize an empty list to store data frames
all_data <- list()

# Loop through each file and extract structured data
for (file_path in files) {
  file_extension <- tools::file_ext(file_path)
  
  if (file_extension == "pdf") {
    # Process PDF files
    pdf_text_content <- c(pdftools::pdf_ocr_text(file_path), file_path)
    data <- chat_liter()$extract_data(pdf_text_content, type = type_summary)
    all_data <- append(all_data, list(data))
    
  } else if (file_extension == "pptx") {
    # Process PowerPoint files
    presentation <- read_pptx(file_path)
    num_slides <- length(presentation)
    slides_text <- list()
    for (i in 1:num_slides) {
      slide_content <- slide_summary(presentation, i)
      slide_text <- paste(slide_content$text, collapse = " ")
      slides_text[[i]] <- slide_text
    }
    all_text <- paste(unlist(slides_text), collapse = "\n--- Slide Separator ---\n")
    textppt <- c(all_text, file_path)
    data <- chat_liter()$extract_data(textppt, type = type_summary)
    all_data <- append(all_data, list(data))
    
  } else if (file_extension == "docx") {
    # Process Word files
    document <- read_docx(file_path)
    doc_summary <- docx_summary(document)
    text_content <- doc_summary$text[!is.na(doc_summary$text)]
    all_text <- paste(text_content, collapse = "\n")
    textdoc <- c(all_text, file_path)
    data <- chat_liter()$extract_data(textdoc, type = type_summary)
    all_data <- append(all_data, list(data))
    
  } else if (file_extension == "msg") {
    # Process MSG files
    msgsummary <- read_msg(file_path)
    msgtext <- msgsummary$body[[1]]
    textmsg <- c(msgtext, file_path)
    data <- chat_liter()$extract_data(textmsg, type = type_summary)
    all_data <- append(all_data, list(data))
  }
}

# ------------------------------------------------------------------------------
# 6. Combine and Save Results
# ------------------------------------------------------------------------------
data_frame <- do.call(rbind, lapply(all_data, as.data.frame))
write.csv(data_frame, "literature_review.csv")

