# backend/main.py

import io
import base64
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from fastapi import FastAPI, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from sklearn.cluster import KMeans

app = FastAPI()

# CORS (allow flutter web)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------------------------
# Helper → Convert Matplotlib chart to Base64
# -------------------------------------------
def fig_to_base64():
    buf = io.BytesIO()
    plt.savefig(buf, format="png", bbox_inches="tight")
    buf.seek(0)
    encoded = base64.b64encode(buf.getvalue()).decode()
    plt.close()
    return encoded


# -------------------------------------------
# ML + Charts Endpoint
# -------------------------------------------
@app.post("/upload_csv/")
async def upload_csv(file: UploadFile):

    # ---------------------
    # Read CSV safely
    # ---------------------
    file_bytes = await file.read()
    try:
        df = pd.read_csv(io.BytesIO(file_bytes), encoding="utf-8")
    except:
        df = pd.read_csv(io.BytesIO(file_bytes), encoding="latin1")

    # ---------------------
    # Keep numeric columns only
    # ---------------------
    numeric_df = df.select_dtypes(include=["number"])

    if numeric_df.empty:
        return {"error": "CSV has no numeric columns. Add numbers like Spend, Age, Orders, etc."}

    # Fill missing values
    numeric_df = numeric_df.fillna(numeric_df.mean())

    # ---------------------
    # ML: KMeans clustering
    # ---------------------
    kmeans = KMeans(n_clusters=3, random_state=42)
    df["Cluster"] = kmeans.fit_predict(numeric_df)

    # Cluster Summary (mean value of each column)
    cluster_summary = numeric_df.copy()
    cluster_summary["Cluster"] = df["Cluster"]
    cluster_summary = cluster_summary.groupby("Cluster").mean().to_dict()

    # Cluster Count
    cluster_count = df["Cluster"].value_counts().to_dict()

    # -------------------------
    # Chart 1: Scatter Plot
    # -------------------------
    plt.figure(figsize=(6, 4))
    sns.scatterplot(
        x=df["Cluster"],
        y=numeric_df.iloc[:, 0],
        hue=df["Cluster"],
        palette="viridis"
    )
    plt.title("Cluster Scatter Plot")
    scatter_b64 = fig_to_base64()

    # -------------------------
    # Chart 2: Heatmap
    # -------------------------
    plt.figure(figsize=(6, 4))
    sns.heatmap(numeric_df.corr(), annot=False, cmap="coolwarm")
    plt.title("Correlation Heatmap")
    heatmap_b64 = fig_to_base64()

    # -------------------------
    # Chart 3: Box Plot
    # -------------------------
    plt.figure(figsize=(6, 4))
    sns.boxplot(data=numeric_df)
    plt.title("Box Plot of Numeric Features")
    boxplot_b64 = fig_to_base64()

    # -------------------------
    # Chart 4: Bar Chart (Cluster Count)
    # -------------------------
    plt.figure(figsize=(6, 4))
    sns.barplot(x=list(cluster_count.keys()), y=list(cluster_count.values()))
    plt.title("Cluster Count Bar Chart")
    bar_b64 = fig_to_base64()

    # -------------------------
    # Return Response
    # -------------------------
    return {
        "cluster_summary": cluster_summary,
        "cluster_count": cluster_count,
        "charts": {
            "scatter": scatter_b64,
            "heatmap": heatmap_b64,
            "boxplot": boxplot_b64,
            "bar": bar_b64
        }
    }
