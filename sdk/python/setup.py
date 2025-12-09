from setuptools import setup, find_packages

setup(
    name="s3-simulator-client",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "requests>=2.25.0",
    ],
    author="Artem Rivnyi",
    description="A Python client for the AWS S3 Simulator API",
    long_description=open("README.md").read() if open("README.md").exists() else "",
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/aws-s3-simulator",
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
)
