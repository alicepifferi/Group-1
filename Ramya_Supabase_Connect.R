# DATA 6520 - Ramya: connect to Supabase and load all four tables
# Open this file in RStudio and click Source.
# First install these packages in the Console (once):
# install.packages(c("httr2", "rstudioapi", "dplyr"))
#
# The publishable key below is intended for student applications.
# Your password is entered privately; no administrator key is needed.
# This is a one-time analytical retrieval, not an auto-updating dashboard.
# Run load_all_data() again to retrieve fresh data. No CSVs are written.
# Do not save your R workspace (.RData), which could retain access tokens.

required <- c("httr2", "rstudioapi", "dplyr")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Install required packages first: ", paste(missing, collapse = ", "))
}
library(httr2)
library(dplyr)

supabase_url <- "https://qfqtowijmmceismaqzxw.supabase.co"
publishable_key <- "sb_publishable_mWe1pU4wX-4YnnaaYqkJSw_5or3gdIM"

# CHANGE THIS - DON'T BE A DUMBASS
student_email <- "alice.pifferi@student.fairfield.edu" 

# 1. Sign in. The local function keeps the password out of the global workspace.
# If authentication fails, confirm email/password and rerun this script.
sign_in <- function() {
  password <- rstudioapi::askForPassword("Ramya: enter your Supabase password")
  if (is.null(password) || !nzchar(password)) stop("Login cancelled: no password entered.")
  response <- request(paste0(supabase_url, "/auth/v1/token")) |>
    req_url_query(grant_type = "password") |>
    req_headers(apikey = publishable_key) |>
    req_body_json(list(email = student_email, password = password)) |>
    req_timeout(60) |>
    req_perform()
  session <- resp_body_json(response)
  if (is.null(session$access_token)) stop("Login did not return an access token.")
  list(token = session$access_token,
       expires_at = Sys.time() + session$expires_in - 30)
}
session <- sign_in()
message("Signed in successfully.")

# 2. Retrieve ALL matching rows, in pages, using a stable unique order.
# Increment by actual rows received, not requested page size: the server may
# enforce a smaller limit. Exact server counts detect incomplete retrieval.
# The count is the number visible to this login, not a bypass of access rules.
get_all_rows <- function(table, key = "employee_id", filters = list(), page_size = 500L) {
  allowed <- c("employees", "compensation_training", "employee_surveys", "exit_interviews")
  if (!table %in% allowed) stop("Unknown table.")
  if (Sys.time() >= session$expires_at) stop("Session expired. Run session <- sign_in() and retry.")
  if (any(names(filters) %in% c("select", "order", "limit", "offset"))) {
    stop("Filters must not override pagination parameters.")
  }
  pages <- list()
  offset <- 0L
  expected <- NULL
  repeat {
    req <- request(paste0(supabase_url, "/rest/v1/", table)) |>
      req_headers(apikey = publishable_key, Prefer = "count=exact") |>
      req_auth_bearer_token(session$token) |>
      req_url_query(select = "*", order = paste0(key, ".asc"),
                    limit = page_size, offset = offset)
    if (length(filters)) req <- do.call(req_url_query, c(list(req), filters))
    response <- req |> req_timeout(60) |> req_perform()
    content_range <- resp_header(response, "content-range")
    total <- suppressWarnings(as.numeric(sub(".*/", "", content_range)))
    if (length(total) != 1L || is.na(total)) stop("Server did not return an exact row count.")
    if (is.null(expected)) expected <- total
    if (total != expected) stop("Row count changed during retrieval. Rerun when data is stable.")
    page <- resp_body_json(response, simplifyVector = TRUE)
    if (expected == 0L) return(tibble())
    if (!is.data.frame(page) || nrow(page) == 0L) {
      stop("Retrieval ended before all rows were received: ", table)
    }
    pages[[length(pages) + 1L]] <- page
    offset <- offset + nrow(page)
    message(table, ": ", offset, " / ", expected, " rows")
    if (offset >= expected) break
  }
  result <- bind_rows(pages)
  if (nrow(result) != expected || anyDuplicated(result[[key]])) {
    stop("Row-count or unique-key validation failed: ", table)
  }
  # Parse ISO date fields into R Date values.
  for (column in grep("_date$", names(result), value = TRUE)) {
    result[[column]] <- as.Date(result[[column]])
  }
  result
}

# 3. Load all four tables. Each invocation makes fresh API requests.
# Separate paginated requests are not a transactionally consistent snapshot;
# avoid instructor edits during this initial analytical retrieval.
load_all_data <- function() {
  list(
    employees = get_all_rows("employees"),
    compensation_training = get_all_rows("compensation_training"),
    employee_surveys = get_all_rows("employee_surveys", "survey_id"),
    exit_interviews = get_all_rows("exit_interviews", "exit_interview_id")
  )
}
data <- load_all_data()
employees <- data$employees
compensation_training <- data$compensation_training
employee_surveys <- data$employee_surveys
exit_interviews <- data$exit_interviews

# 4. Show record counts. Original classroom counts are reference values only;
# live counts may change if the instructor updates the database.
record_counts <- tibble(
  table = names(data),
  retrieved_rows = vapply(data, nrow, integer(1)),
  original_classroom_rows = c(14999L, 14999L, 11567L, 2562L)
)
print(record_counts)
if (any(record_counts$retrieved_rows != record_counts$original_classroom_rows)) {
  warning("Counts differ from the original classroom dataset. Confirm changes/access with your instructor.")
}
if (any(record_counts$retrieved_rows == 0L)) {
  stop("A table has no visible rows. Confirm that data and read-only policies are in place.")
}

# Check one-to-one joins before combining tables.
stopifnot(!anyDuplicated(employees$employee_id))
for (child in list(compensation_training, employee_surveys, exit_interviews)) {
  stopifnot(!anyDuplicated(child$employee_id))
  stopifnot(all(child$employee_id %in% employees$employee_id))
}

# 5. SAMPLE ANALYSIS:
# Within manufacturing, how does the observed cohort departure proportion
# differ between salary bands? This is an association, not evidence of causation.
manufacturing_summary <- employees %>%
  filter(department == "manufacturing") %>%
  left_join(compensation_training, by = "employee_id") %>%
  group_by(salary_band) %>%
  summarise(
    employees = n(),
    departed = sum(left == 1, na.rm = TRUE),
    departure_percent = round(100 * mean(left == 1, na.rm = TRUE), 1),
    average_satisfaction = round(mean(satisfaction_level, na.rm = TRUE), 2),
    average_annual_base_pay = round(mean(annual_base_pay_usd, na.rm = TRUE), 0),
    .groups = "drop"
  )
print(manufacturing_summary)

# 6. SAMPLE LIVE API QUERY:
# Only manufacturing employees who departed. Filtering happens in Supabase;
# all matching records are paginated, so this is not limited to the first page.
manufacturing_departures <- get_all_rows(
  "employees",
  filters = list(department = "eq.manufacturing", left = "eq.1")
)
message("Manufacturing departure query returned ", nrow(manufacturing_departures), " rows.")

# Open tables by clicking them in RStudio's Environment pane, or run:
# View(employees)
# View(compensation_training)
# View(employee_surveys)
# View(exit_interviews)
# View(manufacturing_summary)
#
# To refresh everything, rerun this script (Source). It asks for your password.
# If continuing this session after its token expires: session <- sign_in()
# To remove the token when finished: rm(session)
# No passwords, tokens, or workspace images should be committed to GitHub.
#
# References:
# https://supabase.com/docs/guides/api
# https://supabase.com/docs/guides/auth/passwords
# https://httr2.r-lib.org/
# https://rstudio.github.io/rstudioapi/reference/askForPassword.html
