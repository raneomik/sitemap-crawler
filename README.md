# Sitemap bash crawler

bash tool to crawl websites page links in a sitemap.xml.
Shows estimated time, crawl real-time progress and is configured with a human-friendly YAML file

### usage :

    ./crawler.sh <option>

### options :

|option|details|required|
|:-----:|:-------|:----:|
|-w/--website=<website_conf_name> | crawl a website defined in conf.yml properties | yes (no if -a provided)|
|-a/--all | crawl all websites listed in website_list and in website properties| yes (no if -w provided)|

### Conf.yml file :

the `crawler.sh` reads the conf.yml file, which has to have the following structure :

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
    htaccess:                       #needed if websites under htaccess protection
      user: user
      pass: pass

  dummy:
    domain: http://www.dummy.org
    sitemap: sitemap.xml
    output_file: `date +%d-%m-%Y`-dummy-sitemap.txt
```

The resutls will be recorded in `result` dir and file given in `output_file` conf parameter.
It'll have the following format:

    [checked url],[http response code]



original idea goes to [ReaperSoon](ttps://github.com/ReaperSoon/)

---

### Used tools:
- [Progress Bar](https://github.com/fearside/ProgressBar)
- [YAML parsing & config](https://github.com/jasperes/bash-yaml)
- [Console Colors from ReaperSoon's (& my colab) EurekaPackager - not used for now](https://github.com/ReaperSoon/EurekaPackager)
