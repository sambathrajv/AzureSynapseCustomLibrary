from setuptools import setup, find_namespace_packages

setup(
    name="AzureLibrary.Sample",
    version="1.0",
    package_dir={"": "AzureLibrary"},
    packages=find_namespace_packages(where="src"),
    url="https://sambathraj.com",
    author="Sambathraj",
    zip_safe=True,
)
