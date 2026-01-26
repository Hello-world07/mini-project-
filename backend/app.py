# ------------------------------------------------------
# IMPORTANT: Use non-GUI backend for macOS
# ------------------------------------------------------
import matplotlib
matplotlib.use('Agg')

# ------------------------------------------------------
# Imports
# ------------------------------------------------------
from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt
import seaborn as sns
import base64
from io import BytesIO


# ------------------------------------------------------
# Flask App Setup
# ------------------------------------------------------
app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter Web


# ------------------------------------------------------
# Convert Matplotlib Plot to Base64
# ------------------------------------------------------
def plot_to_base64():
    buffer = BytesIO()
    plt.savefig(buffer, format='png', bbox_inches='tight')
    buffer.seek(0)
    img_bytes = buffer.getvalue()
    plt.close()
    return base64.b64encode(img_bytes).decode()


# ------------------------------------------------------
# UPLOAD CSV ROUTE
# ------------------------------------------------------
@app.route("/upload_csv/", methods=["POST"])
def upload_csv():
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]

    try:
        # FIX: Avoid UTF-8 decoding error by allowing any encoding
        df = pd.read_csv(file, encoding='latin1', encoding_errors='ignore')

        # Keep only numeric columns
        df_numeric = df.select_dtypes(include=['int64', 'float64'])

        if df_numeric.empty:
            return jsonify({"error": "CSV contains no numeric columns"}), 400

        # Apply KMeans clustering
        kmeans = KMeans(n_clusters=3, random_state=42)
        df_numeric["cluster"] = kmeans.fit_predict(df_numeric)

        # Cluster Summary
        cluster_summary = df_numeric.groupby("cluster").mean().to_dict()

        # Cluster Count
        cluster_count = df_numeric["cluster"].value_counts().to_dict()

        # ------------------------------------------------------
        # Scatter Plot (first 2 numeric columns)
        # ------------------------------------------------------
        plt.figure(figsize=(6, 4))
        cols = df_numeric.columns[:2]
        sns.scatterplot(
            x=df_numeric[cols[0]],
            y=df_numeric[cols[1]],
            hue=df_numeric["cluster"]
        )
        scatter_img = plot_to_base64()

        # ------------------------------------------------------
        # Heatmap
        # ------------------------------------------------------
        plt.figure(figsize=(6, 4))
        sns.heatmap(df_numeric.corr(), annot=True)
        heatmap_img = plot_to_base64()

        # ------------------------------------------------------
        # Boxplot
        # ------------------------------------------------------
        plt.figure(figsize=(6, 4))
        sns.boxplot(data=df_numeric)
        boxplot_img = plot_to_base64()

        # ------------------------------------------------------
        # Bar Chart (Cluster Counts)
        # ------------------------------------------------------
        plt.figure(figsize=(6, 4))
        df_numeric["cluster"].value_counts().plot.bar()
        bar_img = plot_to_base64()

        # ------------------------------------------------------
        # API Response
        # ------------------------------------------------------
        return jsonify({
            "cluster_summary": cluster_summary,
            "cluster_count": cluster_count,
            "charts": {
                "scatter": scatter_img,
                "heatmap": heatmap_img,
                "boxplot": boxplot_img,
                "bar": bar_img,
            }
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ------------------------------------------------------
# HOME PAGE TEST ROUTE
# ------------------------------------------------------
@app.route("/", methods=["GET"])
def home():
    return "Customer Segmentation Backend Running 🚀"


# ------------------------------------------------------
# Run Server
# ------------------------------------------------------
if __name__ == "__main__":
    app.run(port=5000, debug=True)
