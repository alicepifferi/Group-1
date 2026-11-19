Alpha Manufacturing --- Employee Retention Analytics
Fairfield University | DATA 6520 -- Analytics Consulting | Group 1
Team: Alice Pifferi, Konstanze Hofmann, John Zaslow
1. Project overview
This project helps Alpha Manufacturing understand employee departures, identify retention priorities, estimate replacement costs, and evaluate potential retention initiatives. The deliverables combine data assessment, statistical analysis, an interactive HR dashboard, and a financial model to support management decisions.
2. Repository contents
  File or folder                                   Purpose                                                                     Status as of November 19, 2026
  Group1_Alpha_SOW.pdf                           Statement of work and project requirements                                  Uploaded

  D1 Data Assessment Report.docx                 Data quality and source assessment                                          Uploaded

  D2 Metric Definitions and Analysis Plan.docx   Metric definitions and analytical methodology                               Uploaded

  D3_Retention_Analysis_Report_Final.docx        Departure patterns, leaver/stayer comparisons and employee voice            Uploaded

  D5_Recommendations_Memo.docx                   Prioritized retention recommendations                                       Uploaded

  alpha_data_connection.R                        Authorized R data retrieval                                                 Uploaded

  logs/                                          Project status and progress documentation                                   Uploaded

  README.md                                      Setup, operation and handoff instructions                                   This document

  alpha_dashboard 2.zip                          D4 dashboard archive; expected to contain app.py and requirements.txt   Uploaded; archive contents to confirm

  D3_retention_analysis.R                        Reproducible D3 analysis                                                    Uploaded

  D5_Cost_Model.xlsx                             D5 replacement costs and hypothetical scenarios                             Uploaded
Retention_Pilot_Executive.pptx                 Executive presentation on retention pilot                                   Uploaded
The inventory reflects the repository screenshot dated November 19, 2026. Upload status does not establish successful execution or final acceptance.
3. Data source and security
The project uses four Supabase tables:
- employees: employee characteristics, employment status and departure dates.
- compensation_training: compensation, training and estimated replacement costs.
- employee_surveys: employee feedback and survey scores.
- exit_interviews: recorded departure reasons.
Access requires an individually authorized Supabase account and an internet connection. The dashboard retrieves data using authenticated read requests. Database permissions must enforce read-only access; application code alone is not a substitute for access controls.

Keep this repository private and restrict access to authorized project participants. An earlier repository screenshot showed Public visibility; the latest file listing does not confirm that this has been corrected. Verify visibility before sharing or uploading additional internal information. Never commit passwords, access tokens, service-role keys, raw employee records, or exported data. Do not share login credentials. Review existing commits for accidental disclosure and notify the project owner if sensitive material was exposed. The application contains a Supabase publishable key, not a service-role credential; access policies must still be verified.
4. Dashboard installation and launch (D4)
Prerequisites
- Python 3 (a current supported version, such as 3.11 or 3.12, is recommended).
- Terminal or command prompt.
- Authorized Supabase email and password.
- app.py and requirements.txt in the same local folder.
Download the repository using GitHub's Code → Download ZIP and extract it. Alternatively, clone the private repository using your authorized GitHub account. Inside the repository, extract alpha_dashboard 2.zip separately. Locate the extracted folder containing both app.py and requirements.txt and open a terminal in that folder. The exact internal folder name has not been verified. If either file is missing, contact the dashboard developer before proceeding. Do not run Streamlit from inside the ZIP archive.
macOS / Linux
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m streamlit run app.py
Windows (Command Prompt)
py -m venv .venv
.venv\Scripts\activate.bat
python -m pip install -r requirements.txt
python -m streamlit run app.py
The requirements file specifies Streamlit >=1.37, pandas >=2.0, NumPy, Plotly >=5.0 and requests. These are minimum or unpinned dependencies, not a fully locked environment.

Open the local URL displayed in the terminal (normally http://localhost:8501). Enter your own Supabase email and password and select Sign in. Wait for the initial live retrieval to finish. To stop the server, press Ctrl+C in the terminal.
5. Dashboard user guide
  Page                                Purpose
  Overview                            Headline departure metrics, replacement costs and key patterns

  Where they leave                    Department, pay band, plant, shift and monthly departure patterns

  Who leaves                          Workload, tenure and leaver/stayer comparisons

  Why they leave                      Exit interview reasons and survey comparisons

  ROI Simulator                       Hypothetical pay-raise cost and benefit analysis

  Savings scenarios                   Estimated replacement costs and hypothetical 5% and 10% reductions
Data and definitions                Data source information and metric definitions
The sidebar contains five categorical filters: department, salary band, plant, shift and job role, plus a departure-month range. These apply to Overview, Where, Who and Why. Use Reset filters to return to the full cohort. Savings scenarios use the full cohort; the ROI Simulator has its own controls. Use Sign out when finished.

The month filter counts employees still employed at the beginning of the selected period and departures occurring during that period. It is not equivalent to dividing monthly departures by the full-year baseline in every month.
6. Live data behavior
The dashboard retrieves fresh data every 60 seconds while the page is active. It uses paginated API requests, checks retrieved counts against server counts, and validates source keys. Compensation records are checked using employee ID and as-of date. The app reconstructs the 2025 cohort from live records: employees present at December 31, 2024, departures in 2025, latest compensation record on or before December 31, 2024, and latest December 2024 survey per employee. Exit interviews are restricted to cohort leavers.

The dashboard does not use Streamlit data caching or write employee data files. It uses in-memory data and session state. The footer displays the retrieval time. If retrieval fails, the application displays an error and retries; expired sessions require signing in again.

Validation limitations: Source-key checks do not guarantee one row per employee after all joins. In particular, multiple exit interviews for an employee could multiply rows. The dashboard also sums available replacement-cost components, so missing costs require separate validation. Verify join cardinality, missing costs and small-group disclosure controls before production handoff. The current code does not enforce a universal minimum group size across all visualizations.
7. Reproducing the original D3 analysis
The D3 report and D5 model use the original fixed cohort, not an unrestricted pull of the updated database. The baseline date is December 31, 2024; the reporting end is December 31, 2025.

Install R and RStudio. The connection workflow uses httr2, rstudioapi and dplyr:
install.packages(c("httr2", "rstudioapi", "dplyr"))
1. Obtain authorized access to the original data version from the project owner. Do not export raw employee records to GitHub.
2. Open alpha_data_connection.R in RStudio and follow the authorized connection workflow. Only retrieve data if the original version is available; do not overwrite an existing verified original session with a new live pull.
3. Confirm the four original tables have the expected counts below and unique employee IDs. Counts alone do not prove version identity; confirm provenance as well.
4. Open D3_retention_analysis.R and run it in the verified R session. It joins the tables and reproduces the group, monthly, survey and exit-interview analyses.
5. Compare the outputs against the D3 report. Stop if any validation fails; do not bypass checks to force the analysis to run.
  Original table            Expected rows
  employees                        14,999
compensation_training            14,999
employee_surveys                 11,567
exit_interviews                   2,562

Expected original results: 3,571 departures, 11,428 stayers, 23.81% departure rate and 76.19% retention rate. The live database may contain additional dated records. Reconstructing the same cohort in Python does not establish that the underlying values are identical to the original R dataset. If the original version is unavailable, exact independent reproduction remains blocked until the data owner provides an authorized version or equivalent validated retrieval method.
8. D5 cost model and recommendations
Open D5_Cost_Model.xlsx from the repository. Review the Baseline, Reasons, Assumptions, Scenarios, Actions, Sensitivity and Readme worksheets alongside D5_Recommendations_Memo.docx.

The original dataset provides estimated recruiting, onboarding and replacement training costs. All 3,571 departures total $34,864,353 in estimated costs. Excluding 82 known eliminated positions leaves 3,489 replacement-eligible departures and $34,100,233 in estimated replacement costs. This assumes remaining departures require replacement; unknown exit reasons may conceal additional eliminated positions.
  Scenario                             Gross savings   Proposed implementation budget        Net savings
  5% fewer eligible departures           $1,705,012                        $700,000        $1,005,012
10% fewer eligible departures          $3,410,023                        $700,000        $2,710,023
Both reductions are hypothetical relative reductions, not forecasts or percentage-point changes. Gross savings assume proportional reductions in replacement costs. The implementation budget is a team-developed planning assumption, pending approval. The dashboard Savings page shows gross savings, whereas the Excel model also deducts proposed implementation costs. The ROI Simulator is a separate hypothetical pay-raise analysis.

Recommended priorities are supervisor development, career development, scheduling/workload optimization and targeted compensation review. D3 associations do not establish causation. Use the memo and model to evaluate pilot programs and track outcomes before scaling.
9. Key metric definitions
- Departure rate: departures divided by the applicable starting cohort.
- Retention rate: stayers divided by the starting cohort for the full-year analysis.
- Replacement cost: estimated recruiting + onboarding + replacement training costs.
- Exit reason share: employees reporting a reason divided by relevant exit-interview respondents.
- Gross scenario savings: eligible replacement cost multiplied by the hypothetical reduction percentage.
- Net savings: gross savings minus implementation costs.
- ROI: net savings divided by implementation costs, expressed as a percentage.
Refer to D2 for the detailed analysis plan and definitions. Survey and exit-interview results are limited by nonresponse; financial estimates exclude lost productivity unless explicitly modeled.
10. Troubleshooting
  Issue                                        Recommended action
  Python or Streamlit not found                Verify Python installation, activate the virtual environment and reinstall requirements.

  app.py not found                             Open the terminal in the folder containing app.py and requirements.txt.

  Login failed                                 Verify your own authorized Supabase credentials; contact the project owner if access is missing.

  Session expired                              Sign out and sign in again.

  Database retrieval or key validation error   Check internet access and retry. If persistent, contact the data owner; do not disable validation.

  No employees match filters                   Reset filters or choose a different combination.

  R row counts differ from original            Stop and confirm the original data version with the data owner.
Dashboard and report totals differ           Check filters, cohort reconstruction, data version, join cardinality and cost completeness.
11. Executive presentation and project tracking
Open Retention_Pilot_Executive.pptx for the executive presentation. Use the D5 workbook and memo for detailed financial assumptions and recommendations. The presentation has been uploaded, but its contents and consistency with the final model have not been independently verified. Use GitHub Issues and Projects to track epics, features, user stories, tasks and review status; use logs/ to record progress and verification evidence.
12. Handoff and verification (D6)
Before final acceptance, an authorized person outside the development team should follow this README on a clean environment and document the outcome in the project logs.
- [ ] Repository access restricted and committed files reviewed for sensitive information.
- [ ] Confirm the dashboard archive contains the required scripts and dependencies; confirm remaining D6/D7 deliverables against the SOW.
- [ ] Independent user installs dependencies and launches the dashboard.
- [ ] Authorized login, navigation, filters, reset and sign-out tested.
- [ ] Live refresh and error handling tested.
- [ ] Cohort, join cardinality, missing costs and disclosure controls verified.
- [ ] Original D3 results independently reproduced or version-access blocker documented.
- [ ] D5 formulas independently checked and memo reconciled.
- [ ] Implementation assumptions reviewed by instructor/client representative.
- [ ] Final handoff outcome recorded with date, reviewer and any unresolved issues.
These are verification steps, not a claim that all tests have passed. Record independent D3/D5 verification as successful only after a reviewer actually completes the relevant checks. The dashboard archive itself has not been inspected or launched during this README update. Record completed checks and evidence in logs/ and GitHub Issues/Projects. Direct access or data-version questions to the project owner or instructor.
