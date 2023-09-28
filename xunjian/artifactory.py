from urllib.parse import urljoin
from requests import get, post, put, delete, Response
from utils.log import logger


class Artifactory(object):
    def __init__(self, base_url: str, api_key: str) -> None:
        """
        Args:
            base_url (str): base url
            api_key (str): user api key
        """
        self.base_url = base_url
        self.api_key = api_key
        self.headers = {
            "X-JFrog-Art-Api": api_key,
        }
        self.timeout = 10

    def _post(self, uri: str, headers: dict = None, data: str = None) -> Response:
        headers = headers or self.headers
        headers.update({
            "Content-Type": "text/plain"
        })
        data = data or ""
        url = urljoin(self.base_url, uri)
        response = post(url=url, headers=headers,
                        data=data, timeout=self.timeout)
        logger.debug(response.text)
        return response

    def _put(self, uri: str, params: dict = None, data: str = None) -> Response:
        data = data or ""
        url = urljoin(self.base_url, uri)
        response = put(url=url, headers=self.headers,
                       params=params, data=data, timeout=self.timeout)
        logger.debug(response.text)
        return response

    def _delete(self, uri: str) -> Response:
        url = urljoin(self.base_url, uri)
        response = delete(url=url, headers=self.headers, timeout=self.timeout)
        logger.debug(response.text)
        return response

    def _get(self, uri: str, headers: dict = None, params: dict = None) -> Response:
        headers = headers or self.headers
        headers.update(self.headers)
        params = params or {}
        url = urljoin(self.base_url, uri)
        response = get(url=url, headers=headers,
                       params=params, timeout=self.timeout)
        logger.debug(response.text)
        return response

    def get_system_license(self):
        response = self._get(uri="/artifactory/api/system/license")
        return response.json()

    def get_storage_info(self):
        response = self._get(uri="/artifactory/api/storageinfo").json()
        sorted_data = sorted(response["repositoriesSummaryList"],
                             key=lambda x: self.convert_to_bytes(
                                 x["usedSpace"]),
                             reverse=True)
        response.update({"repositoriesSummaryList": sorted_data})
        return response

    @staticmethod
    def convert_to_bytes(size: str):
        units = {
            "bytes": 1,
            "KB": 1024,
            "MB": 1024**2,
            "GB": 1024**3,
            "TB": 1024**4
        }
        number, unit = size.split()
        return float(number) * units[unit]
