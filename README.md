# Sitemap bash crawler

bash tool to crawl page links in a sitmap.xml

usage :

    ./crawl.sh <option>

options :

|option|details|required|
|:-----:|:-------|:----:|
|-w/--website=<website_conf_name> | crawl a website defined in conf.yml properties | yes (no if -a provided)|
|-a/--all | crawl all websites listed in website_list and in website properties| yes (no if -w provided)|

Conf.yml file :

the crawl.sh reads the conf.yml file, which has to have the following structure :

```yml
websites:
  list: # required for -a option : crawl all listed websites
    - example
    - dummy

  example:                          # site name defined in 'list' property
    domain: http://www.example.com  # site url where to fetch the sitemap
    sitemap: sitemap.xml            # sitemaps filename
    output_file: `date +%d-%m-%Y`-example-sitemap.txt # where to store results (relative to 'results' directory, that will be created)
    404_only: true                  #[optional] store only 404 error pages
  dummy:
    domain: http://www.dummy.org
    sitemap: sitemap.xml
    output_file: `date +%d-%m-%Y`-dummy-sitemap.txt
```