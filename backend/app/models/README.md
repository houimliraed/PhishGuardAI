# Phishing Detection Models

This directory contains the trained machine learning models for phishing detection.

## Model Files

- `phishing_model.pkl` - RandomForest classifier for phishing detection
- `scaler.pkl` - StandardScaler for feature normalization

## Generating Models

To generate/update the models, run the training notebook:

```bash
jupyter notebook ../../../notebooks/phishing_detection_training.ipynb
```

Or use the notebook in VS Code Jupyter extension and execute the model generation cell.

**Note:** Model files are not tracked in git as they are generated artifacts. They must be regenerated when deploying.
