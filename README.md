# your-repo

一个带 GitHub Actions CI 的 Python 示例项目。自带 pytest、pytest-cov 等开发依赖。

## 本地运行
```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -U pip
pip install -e .[dev]
python -m pytest -q --junitxml=target/test.xml --cov=your_package --cov-report=xml:target/coverage.xml
```
