import os
import unittest
import requests
from unittest import TestCase
from unittest.mock import patch
import requests

# Assuming fetchUserGroups is defined in the app module
from app import extract_value, fetchUserGroups, format_as_ndjson, formatApiResponseNoStreaming, formatApiResponseStreaming, generateFilterString, parse_multi_columns, prepare_body_headers_with_data

AZURE_SEARCH_SERVICE = os.environ.get("AZURE_SEARCH_SERVICE", "mysearchservice")
AZURE_OPENAI_KEY = os.environ.get("AZURE_OPENAI_KEY", "api_key")
AZURE_SEARCH_PERMITTED_GROUPS_COLUMN = os.environ.get("AZURE_SEARCH_PERMITTED_GROUPS_COLUMN","fake_token")

class TestYourFunctions(unittest.TestCase):

    def test_format_as_ndjson(self):
        obj = {"key": "value"}
        result = format_as_ndjson(obj)
        self.assertEqual(result, '{"key": "value"}\n')

    def test_parse_multi_columns(self):
        self.assertEqual(parse_multi_columns("a|b|c"), ["a", "b", "c"])
        self.assertEqual(parse_multi_columns("a,b,c"), ["a", "b", "c"])

    @patch('requests.get')
    def test_success_single_page(self, mock_get):
        # Mock response for a single page of groups
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {
            "value": [{"id": "group1"}, {"id": "group2"}]
        }
        
        userToken = "valid_token"
        result = fetchUserGroups(userToken)
        expected = [{"id": "group1"}, {"id": "group2"}]
        self.assertEqual(result, expected)

    @patch('requests.get')
    def test_success_multiple_pages(self, mock_get):
        # Mock response for multiple pages of groups
        mock_get.side_effect = [
            # First page with a next link
            self._mock_response(200, {
                "value": [{"id": "group1"}, {"id": "group2"}],
                "@odata.nextLink": "https://next.page"
            }),
            # Second page
            self._mock_response(200, {
                "value": [{"id": "group3"}]
            })
        ]
        
        userToken = "valid_token"
        result = fetchUserGroups(userToken)
        expected = [{"id": "group1"}, {"id": "group2"}, {"id": "group3"}]
        self.assertEqual(result, expected)

    @patch('requests.get')
    def test_non_200_status_code(self, mock_get):
        # Mock response with a 403 Forbidden error
        mock_get.return_value.status_code = 403
        mock_get.return_value.text = "Forbidden"
        
        userToken = "valid_token"
        result = fetchUserGroups(userToken)
        expected = []
        self.assertEqual(result, expected)

    @patch('requests.get')
    def test_exception_handling(self, mock_get):
        # Mock an exception when making the request
        mock_get.side_effect = Exception("Network error")
        
        userToken = "valid_token"
        result = fetchUserGroups(userToken)
        expected = []
        self.assertEqual(result, expected)

    @patch('requests.get')
    def test_no_groups_found(self, mock_get):
        # Mock response with no groups found
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {
            "value": []
        }
        
        userToken = "valid_token"
        result = fetchUserGroups(userToken)
        expected = []
        self.assertEqual(result, expected)

    def _mock_response(self, status_code, json_data):
        """Helper method to create a mock response object."""
        mock_resp = unittest.mock.Mock()
        mock_resp.status_code = status_code
        mock_resp.json.return_value = json_data
        return mock_resp
    
    @patch('app.fetchUserGroups')
    def test_generateFilterString(self, mock_fetchUserGroups):
        mock_fetchUserGroups.return_value = [{'id': '1'}, {'id': '2'}]
        userToken = "fake_token"

        filter_string = generateFilterString(userToken)
        self.assertEqual(filter_string, "/any(g:search.in(g, '1, 2'))")


    @patch('app.requests.post')  # Mock the requests.post method if needed
    def test_prepare_body_headers_with_data(self, mock_post):
        # Mock the response of requests.post if it is actually used in the function
        mock_post.return_value.json.return_value = {"some": "data"}
        mock_post.return_value.status_code = 200

        # Change MockRequest to return a dictionary directly from the json method
        class MockRequest:
            @property
            def json(self):
                return {"messages": [{"role": "user", "content": "Hello"}], "index_name": "grants"}

            @property
            def headers(self):
                return {'X-MS-TOKEN-AAD-ACCESS-TOKEN': 'fake_token'}

        # Call the function with the mocked request
        body, headers = prepare_body_headers_with_data(MockRequest())

        # Assertions to check if the expected values are in the body
        self.assertIn("dataSources", body)
        self.assertGreater(len(body["dataSources"]), 0)
        self.assertIn("parameters", body["dataSources"][0])
        self.assertEqual(body["dataSources"][0]["parameters"]["endpoint"], f"https://{AZURE_SEARCH_SERVICE}.search.windows.net")
        self.assertEqual(headers['Content-Type'], 'application/json')
        self.assertEqual(headers['api-key'], AZURE_OPENAI_KEY)
        self.assertEqual(headers['x-ms-useragent'], "GitHubSampleWebApp/PublicAPI/3.0.0")

    def test_formatApiResponseNoStreaming(self):
        rawResponse = {
            "id": "1",
            "model": "gpt-3",
            "created": 123456789,
            "object": "response",
            "choices": [{
                "message": {
                    "context": {"messages": [{"content": "Hello from tool"}]},
                    "content": "Hello from assistant"
                }
            }]
        }
        response = formatApiResponseNoStreaming(rawResponse)
        self.assertIn("choices", response)
        self.assertEqual(response["choices"][0]["messages"][0]["content"], "Hello from tool")

    def test_formatApiResponseStreaming(self):
        rawResponse = {
            "id": "1",
            "model": "gpt-3",
            "created": 123456789,
            "object": "response",
            "choices": [{
                "delta": {
                    "role": "assistant",
                    "content": "Hello"
                }
            }]
        }
        
        response = formatApiResponseStreaming(rawResponse)
        
        # Print response to debug
        print(response)  # Optional for debugging, remove in production
        
        self.assertIn("choices", response)
        self.assertIn("messages", response["choices"][0])
        self.assertEqual(len(response["choices"][0]["messages"]), 1)  # Ensure there's one message

        # Check if the content is included under the correct structure
        delta_content = response["choices"][0]["messages"][0]["delta"]
        self.assertIn("role", delta_content)  # Check for role
        self.assertNotIn("content", delta_content)  # content should not be present as per current logic

    def test_extract_value(self):
        text = "'code': 'content_filter', 'status': '400'"
        self.assertEqual(extract_value('code', text), 'content_filter')
        self.assertEqual(extract_value('status', text), '400')
        self.assertEqual(extract_value('unknown', text), 'N/A')

if __name__ == '__main__':
    unittest.main()
