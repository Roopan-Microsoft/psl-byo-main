import os
from unittest.mock import MagicMock, patch

import pytest
import requests_mock
from flask import json

from app import app, fetchUserGroups


@pytest.fixture
def client():
    with app.test_client() as client:
        yield client


# Test for the index route
def test_index(client):
    with patch("flask.Flask.send_static_file") as mock_send_static_file:
        mock_send_static_file.return_value = "Mocked index.html"
        response = client.get("/")
        assert response.status_code == 200
        assert response.data.decode("utf-8") == "Mocked index.html"


@patch("requests.Session.post")
@patch("requests.get")
def test_conversation_success_streaming(mock_get, mock_post, client):
    with patch("app.SHOULD_STREAM", True):
        mock_get.return_value = MagicMock(
            status_code=200, json=lambda: {"value": [{"id": "group1"}]}
        )
        mock_post.return_value = MagicMock(
            status_code=200,
            json=lambda: {
                "id": "1",
                "model": "gpt-model",
                "created": 1234567890,
                "object": "completion",
                "choices": [
                    {
                        "message": {
                            "context": {
                                "messages": [
                                    {
                                        "role": "assistant",
                                        "content": "response",
                                    }
                                ]
                            },
                            "content": "response",
                        }
                    }
                ],
            },
        )
        response = client.post(
            "/conversation",
            json={
                "messages": [{"role": "user", "content": "Hello"}],
                "index_name": "grants",
            },
            headers={"X-MS-TOKEN-AAD-ACCESS-TOKEN": "mock-token"},
        )
        assert response.status_code == 200


@patch("app.conversation_with_data")
@patch("requests.get")
def test_conversation_streaming_internal_server_error(
    mock_get, mock_conversation_with_data, client
):
    # Simulate a valid response for group membership
    mock_get.return_value = MagicMock(
        status_code=200, json=lambda: {"value": [{"id": "group1"}]}
    )

    # Simulate the conversation_with_data method raising an exception or returning a 500 error
    mock_conversation_with_data.side_effect = Exception("Internal Server Error")

    # Prepare the request body for streaming
    request_body = {
        "messages": [{"role": "user", "content": "Hello"}],
        "index_name": "grants",  # Assuming this is required
    }

    # Simulate the POST request for conversation endpoint
    response = client.post(
        "/conversation",
        json=request_body,
        headers={"X-MS-TOKEN-AAD-ACCESS-TOKEN": "mock-token"},
    )

    # Assert that the response status code is 500 due to internal server error
    assert response.status_code == 500

    # Check that the response contains the error message
    assert "error" in response.json


@patch("requests.post")
@patch("requests.get")
@patch.dict(
    os.environ,
    {
        "AI_STUDIO_CHAT_FLOW_ENDPOINT": "http://test-endpoint",
        "AI_STUDIO_CHAT_FLOW_API_KEY": "test-api-key",
        "AI_STUDIO_CHAT_FLOW_DEPLOYMENT_NAME": "test-deployment",
    },
)
def test_conversation_success_streaming_data(mock_get, mock_post, client):
    with patch("app.SHOULD_STREAM", True), patch("app.USE_AZURE_AI_STUDIO", "true"):
        with requests_mock.Mocker() as m:
            m.get("http://test-endpoint", json={"value": [{"id": "group1"}]})
            m.post(
                "http://test-endpoint",
                headers={"apim-request-id": "test_request_id"},
                text="""data: {"answer": "{\\"id\\": \\"test_id\\", \\"model\\": \\"test_model\\", \\"created\\": 1234567890, \\"object\\": \\"test_object\\", \\"choices\\": [{\\"messages\\": [{\\"delta\\": {\\"content\\": \\"test_content\\"}}]}]}"}\ndata: {"answer": "{\\"id\\": \\"test_id\\", \\"model\\": \\"test_model\\", \\"created\\": 1234567891, \\"object\\": \\"test_object\\", \\"choices\\": [{\\"messages\\": [{\\"delta\\": {\\"content\\": \\"[DONE]\\"}}]}]}"}""",
            )

            response = client.post(
                "/conversation",
                json={
                    "messages": [{"role": "user", "content": "Hello"}],
                    "index_name": "grants",
                },
                headers={"X-MS-TOKEN-AAD-ACCESS-TOKEN": "mock-token"},
            )
            assert response.status_code == 200


@patch("requests.post")
@patch("requests.get")
def test_conversation_success_no_streaming(mock_get, mock_post, client):
    with patch("app.SHOULD_STREAM", False):
        mock_get.return_value = MagicMock(
            status_code=200, json=lambda: {"value": [{"id": "group1"}]}
        )
        mock_post.return_value = MagicMock(
            status_code=200,
            json=lambda: {
                "id": "1",
                "model": "gpt-model",
                "created": 1234567890,
                "object": "completion",
                "choices": [
                    {
                        "message": {
                            "context": {
                                "messages": [
                                    {
                                        "role": "assistant",
                                        "content": "response",
                                    }
                                ]
                            },
                            "content": "response",
                        }
                    }
                ],
            },
        )
        response = client.post(
            "/conversation",
            json={
                "messages": [{"role": "user", "content": "Hello"}],
                "index_name": "grants",
            },
            headers={"X-MS-TOKEN-AAD-ACCESS-TOKEN": "mock-token"},
        )
        assert response.status_code == 200


@patch("requests.get")
def test_fetchUserGroups_failure(mock_get):
    mock_get.return_value = MagicMock(status_code=401, text="Unauthorized")
    groups = fetchUserGroups("invalid-token")
    assert groups == []


# @patch("app.prepare_body_headers_with_data")
@patch("app.requests.post")
def test_conversation_success(mock_post, client):
    with patch("app.DEBUG_LOGGING", "true"), patch(
        "app.AZURE_SEARCH_PERMITTED_GROUPS_COLUMN", "Test"
    ), patch("app.AZURE_SEARCH_QUERY_TYPE", "vector"):
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "id": "test",
            "model": "gpt-4",
            "choices": [
                {"messages": [{"role": "assistant", "content": "Test response"}]}
            ],
        }
        mock_post.return_value = mock_response

        data = {
            "messages": [{"role": "user", "content": "Hello"}],
            "history_metadata": {},
            "index_name": "grants",
        }
        response = client.post("/conversation", json=data)

        assert response.status_code == 200


# Test for conversation endpoint - Missing required field
def test_conversation_missing_field(client):
    data = {"history_metadata": {}}
    response = client.post("/conversation", json=data)
    assert response.status_code == 500
    assert b"error" in response.data


# Test for fetchUserGroups edge case - No user groups
@patch("app.requests.get")
def test_fetch_user_groups_no_groups(mock_get):
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"value": []}
    mock_get.return_value = mock_response

    from app import fetchUserGroups

    result = fetchUserGroups("dummy_token")
    assert result == []


# Test for fetchUserGroups with multiple pages of results
@patch("app.requests.get")
def test_fetch_user_groups_multiple_pages(mock_get):
    first_page = {"value": [{"id": "group1"}], "@odata.nextLink": "http://nextpage"}
    second_page = {"value": [{"id": "group2"}]}

    mock_get.side_effect = [
        MagicMock(status_code=200, json=lambda: first_page),
        MagicMock(status_code=200, json=lambda: second_page),
    ]

    from app import fetchUserGroups

    result = fetchUserGroups("dummy_token")
    assert result == [{"id": "group1"}, {"id": "group2"}]


@patch("urllib.request.urlopen")
@patch.dict(
    os.environ,
    {
        "AI_STUDIO_DRAFT_FLOW_ENDPOINT": "http://test-endpoint",
        "AI_STUDIO_DRAFT_FLOW_API_KEY": "test-api-key",
        "AI_STUDIO_DRAFT_FLOW_DEPLOYMENT_NAME": "test-deployment",
    },
)
def test_draft_document_generate_success(mock_urlopen, client):
    mock_response = MagicMock()
    mock_response.read.return_value = json.dumps(
        {"reply": "Generated section content"}
    ).encode("utf-8")
    mock_urlopen.return_value = mock_response

    # Test the endpoint
    request_data = {
        "grantTopic": "AI Research",
        "sectionTitle": "Introduction",
        "sectionContext": "This section introduces AI research.",
    }
    response = client.post("/draft_document/generate_section", json=request_data)

    assert response.status_code == 200
    assert b"Generated section content" in response.data


def test_get_frontend_settings_success(client):
    """Test for successful retrieval of frontend settings"""
    response = client.get("/frontend_settings")

    # Assert status code is 200
    assert response.status_code == 200

    # Assert that the response JSON is as expected
    expected_data = {"auth_enabled": "true"}
    assert response.get_json() == expected_data
