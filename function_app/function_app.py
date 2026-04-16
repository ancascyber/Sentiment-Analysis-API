import azure.functions as func
import json
import logging
import os
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

def get_language_client():
    endpoint = os.environ["LANGUAGE_ENDPOINT"]
    key = os.environ["LANGUAGE_KEY"]
    return TextAnalyticsClient(endpoint=endpoint,
                              credential=AzureKeyCredential(key))

@app.route(route="sentiment", methods=["POST"])
def sentiment(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Sentiment endpoint called")

    try:
        body = req.get_json()
        text = body.get("text", "")

        if not text:
            return func.HttpResponse(
                json.dumps({"error": "text field is required"}),
                mimetype="application/json",
                status_code=400
            )

        client = get_language_client()

        sentiment_result = client.analyze_sentiment([text])[0]
        key_phrases = client.extract_key_phrases([text])[0]

        response = {
            "sentiment": sentiment_result.sentiment,
            "confidence": {
                "positive": round(sentiment_result.confidence_scores.positive, 2),
                "neutral":  round(sentiment_result.confidence_scores.neutral, 2),
                "negative": round(sentiment_result.confidence_scores.negative, 2)
            },
            "key_phrases": list(key_phrases.key_phrases),
            "language": "en"
        }

        return func.HttpResponse(
            json.dumps(response),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        logging.error(f"Error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": "Internal server error"}),
            mimetype="application/json",
            status_code=500
        )
