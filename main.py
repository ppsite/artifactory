import os
import fire
import yaml
import boto3
from jinja2 import Environment, FileSystemLoader
from xunjian.host import Host
from xunjian.artifactory import Artifactory
from utils.log import logger


class Xunjian:
    def __init__(self, config: str) -> None:
        # 加载配置文件
        with open(config, "r", encoding="utf-8") as f:
            self.conf = yaml.safe_load(f)
        # 初始化数据
        data = {
            "base_url": os.environ.get("BASE_URL"),
        }

        # 实例化功能模块
        artifacory = Artifactory(base_url=self.conf["artifactory"]["base_url"],
                                 api_key=self.conf["artifactory"]["api_key"])
        host = Host()

        # 循环执行模块方法, 准备巡检数据
        for module in [host, artifacory]:
            methods = [method for method in dir(module) if callable(
                getattr(module, method)) and method.startswith("get_")]
            for method in methods:
                f = getattr(module, method)
                try:
                    data[method] = f()
                except Exception as error:
                    logger.error("%s.%s error: %s",
                                 module.__class__.__name__, method, error)

        # 渲染 HTML
        env = Environment(loader=FileSystemLoader("./templates"))
        template = env.get_template("report.html")
        self.html = template.render(data=data)

    def local(self, file: str = "./report.html"):
        """输出到本地文件

        Args:
            file (str): local file path (default: ./report.html)
        """
        with open(file, "w", encoding="utf-8") as f:
            f.write(self.html)

    def remote(self, bucket: str, key: str):
        """将巡检报告保存到远端 S3

        Args:
            bucket (str): 存储桶
            key (str): 对象 Key
        """
        print(self.conf["s3"]["endpoint_url"], self.conf["s3"]
              ["aws_access_key_id"], self.conf["s3"]["aws_secret_access_key"])
        local_file = "./report.html"
        self.local(file=local_file)
        client = boto3.client(service_name="s3",
                              endpoint_url=self.conf["s3"]["endpoint_url"],
                              aws_access_key_id=self.conf["s3"]["aws_access_key_id"],
                              aws_secret_access_key=self.conf["s3"]["aws_secret_access_key"],
                              region_name=self.conf["s3"]["region_name"])
        print(bucket, key)
        client.put_object(Body=self.html, Bucket=bucket, Key=key)
        # os.remove(local_file)
        print(f"Report saved to {bucket}/{key}")


if __name__ == "__main__":
    fire.Fire(Xunjian)
