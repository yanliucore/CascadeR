# Leveraging Large Language Models in R with Three Applications

These three R scripts automate data analysis tasks using Azure OpenAI services: (1) extracting summaries from a ggplot, (2) classifying mental health-related text into sentiment categories, and (3) extracting structured summaries from research documents. Each script sets up Azure authentication, defines a function to interact with the OpenAI API, designs a structured prompt for the large language model (LLM), and processes input data (plots, text, or documents) to return structured outputs such plot descriptions, sentiment probabilities, or article summaries. The workflows are designed for batch processing, error handling, and saving results to CSV files for further analysis.  

## Automated Plot Summary and Metadata Extraction  
### Purpose: Extracts structured metadata (title, axes, legend) and a summary from a plot using Azure OpenAI.  
### How it works:  
Loads required libraries.  
Sets up Azure credentials.  
Defines a function to authenticate and send prompts to Azure OpenAI.  
Designs a prompt for extracting plot details.  
Main function (chat_azure_core_plot) analyzes a plot and returns requested metadata.  
Example: Summarizes a bar plot of average claim amounts by region and status.  

## Mental Health Sentiment Classification Pipeline  
### Purpose: Classifies mental health-related text into sentiment categories using Azure OpenAI.  
### How it works:  
Loads required libraries.  
Loads a dataset from CSV. (data source: https://www.kaggle.com/datasets/suchintikasarkar/sentiment-analysis-for-mental-health)  
Sets up Azure credentials.  
Defines a function to interact with Azure OpenAI.  
Designs a prompt for classifying text into categories (Anxiety, Bipolar, Depression, etc.).  
Loops through dataset, sends each text to the LLM, parses probabilities, and saves results to a CSV.  
Calculates and prints accuracy after each batch.  

## Literature Review Extraction Pipeline  
### Purpose: Automates extraction of structured summaries from research documents (PDF, PPTX, DOCX, MSG) using Azure OpenAI.  
### How it works:  
Loads required libraries for file handling and text extraction.  
Sets up Azure credentials.  
Defines a function to interact with Azure OpenAI for extracting article metadata.  
Designs a prompt for extracting structured article information (title, author, summary, methods, etc.).  
Loops through all files in a folder, extracts text, sends to LLM, and compiles results into a CSV.  


