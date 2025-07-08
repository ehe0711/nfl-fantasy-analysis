# Fantasy Football Wide Receiver Projections

This project predicts fantasy football wide receiver performance using statistical modeling and compares those predictions to expert rankings. The analysis covers data cleaning, feature engineering, model fitting, validation, and comparison with expert and actual results.

---

## Project Structure

fantasy_football_projections/
├── data/
│ ├── filtered_players.csv
│ ├── fantasypoints_2023.csv
│ ├── age_2023.csv
│ ├── yprr_2022.csv
│ ├── competition_change2023.csv
│ ├── qb_skill2023.csv
│ ├── target_share2022.csv
│ ├── Vfiltered_players.csv
│ ├── Vfantasy_points2024.csv
│ ├── Vage2024.csv
│ ├── Vyprr2023.csv
│ ├── Vcomp_change2024.csv
│ ├── Vqb_skill2024.csv
│ ├── Vtarget_share2023.csv
│ ├── actual_top24.csv
│ ├── expert_top24.csv
│ └── model_top24.csv
├── main_analysis.R
└── README.md


---


---

## How to Run

1. **Install required R packages:**
    ```
    install.packages(c("dplyr", "readr", "stringr", "ggplot2", "Hmisc", "sjPlot", "MASS", "car", "condformat", "corrplot", "lmtest"))
    ```

2. **Open `main_analysis.R` in RStudio or your preferred R environment.**

3. **Set your working directory** to the project folder if necessary:
    ```
    setwd("C:/Users/tianc/OneDrive/Desktop/Projects/fantasy_football_projections")
    ```

4. **Run the script from top to bottom.**  
   All outputs (plots, tables, summaries) will be saved in the `results/` folder.

---

## Data Sources

- `filtered_players.csv`: List of WRs filtered for analysis (2023)
- `fantasypoints_2023.csv`: Actual fantasy points scored in 2023
- `age_2023.csv`: Player ages heading into the 2023 NFL season
- `yprr_2022.csv`: Yards per route run (2022)
- `competition_change2023.csv`: Competition change metric (2023)
- `qb_skill2023.csv`: Quarterback skill rating (2023)
- `target_share2022.csv`: Target share (2022)
- **Validation files:** Same variables for 2024 projections (prefixed with `V`)
- `actual_top24.csv`, `expert_top24.csv`, `model_top24.csv`: Top 24 WR rankings (actual, expert, model)

---

## Analysis Workflow

1. **Data Cleaning**
   - Standardize player names across all datasets.
   - Address naming inconsistencies (e.g., "Allen Robinson II", "Joshua Palmer").
   - Remove players with missing fantasy points.

2. **Feature Engineering & Merging**
   - Merge all relevant data into a single master dataset.
   - Prepare a validation set for 2024 predictions.

3. **Exploratory Data Analysis**
   - Visualize distributions (histograms, bar charts).
   - Calculate and plot correlation matrices.

4. **Modeling**
   - Fit a linear regression model predicting 2023 fantasy points from 2022/2023 factors.
   - Diagnose model assumptions (linearity, normality, heteroskedasticity, multicollinearity).
   - Fit a robust regression model to reduce outlier sensitivity.

5. **Validation**
   - Use the 2023 model to predict 2024 fantasy points.
   - Calculate RMSE and R² on the validation set.
   - Visualize residuals and investigate outliers.

6. **Comparison with Experts**
   - Compare model and expert top 24 WR rankings to actual results.
   - Calculate Mean Absolute Rank Error (MARE) for both.
   - Visualize top 12 accuracy using conditional formatting.

---

## Key Results

| Metric                              | Value   |
|--------------------------------------|--------:|
| **Validation RMSE**                  | 71.6    |
| **Validation R²**                    | 0.419   |
| **Robust Model RMSE**                | 72.65   |
| **Robust Model R²**                  | 0.418   |
| **Mean Absolute Rank Error (Model)** | 8.581   |
| **Mean Absolute Rank Error (Expert)**| 6.674   |

---

## Outputs

- **Plots:** Distribution histograms, correlation matrices, residual plots, comparison tables.
- **Tables:** Top 24 WRs by model prediction, expert, and actual results.
- **Formatted comparison matrix:** Conditional highlighting for top 12 accuracy.
- **Model summaries and validation metrics:** Saved as text files in `results/`.

---

## Limitations

- **Data Quality:** The analysis relies on publicly available NFL statistics. Any missing, outdated, or inconsistent data may impact model accuracy.
- **Feature Selection:** Only a subset of potentially predictive variables (e.g., target share, YPRR, competition change, QB skill, age) are included. Other relevant features may improve performance.
- **Model Complexity:** Linear and robust regression models are used, which may not capture complex or nonlinear relationships present in the data.
- **Expert Comparison:** Expert rankings are based on external methodologies that may differ from the model’s approach and assumptions.
- **Generalizability:** The model is trained and validated on recent seasons; performance on future seasons may require retraining or adjustment.
- **Conditional Formatting Export:** Color highlights in comparison matrices are best preserved in HTML or PDF. Direct image exports may not retain all formatting.

---

## Future Work

- **Expand Feature Set:** Incorporate additional advanced stats (e.g., air yards, injury history, team context).
- **Explore Machine Learning:** Test alternative models such as random forests, gradient boosting, or neural networks.
- **Automate Data Updates:** Develop scripts or pipelines to automatically update data as new seasons are released.
- **Interactive Dashboards:** Build Shiny apps or dashboards for interactive visualization and exploration.
- **Position Expansion:** Apply the methodology to other positions (e.g., running backs, tight ends).
- **Deeper Error Analysis:** Investigate cases where model and expert predictions diverge, and analyze outliers in more detail.

---

## How to Contribute

- **Report Issues:** If you find bugs or data issues, please open an issue or contact the maintainer.
- **Submit Pull Requests:** Fork this repository, make your improvements, and submit a pull request with a clear description of your changes.
- **Suggest Features:** Open an issue or discussion for new features, enhancements, or data sources.
- **Improve Documentation:** Contributions to the README or code comments are welcome to help new users and collaborators.
- **Share Data:** If you have access to better or additional data, please suggest integration or share sources.

---


## How to Cite

If you use this code or results, please cite:  
Ethan He, "Fantasy Football Wide Receiver Projections", 2025.

---

## Contact

For questions or collaboration, contact:  
tiancheng.ethan.he@gmail.com

---

**Tips:**
- For best results, ensure all required CSVs are in the `data/` folder before running the script.
- All outputs will be saved in the `results/` folder for easy access and reporting.
- For publication or sharing, you can export tables/plots from the `results/` folder as needed.
