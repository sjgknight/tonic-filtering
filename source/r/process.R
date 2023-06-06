#pacman::p_load_gh("matthewjrogers/rairtable")
# set_airtable_api_key('', install = TRUE)
#principles <- airtable('Principles', 'appFOCCNDUuGhYPB2')
#airtable_data <- read_airtable(principles, id_to_col = TRUE, max_rows = 50000)

pacman::p_load(magrittr, dplyr, tidyjson, purrr)

shell("pip install airtable-export")
shell(paste0("airtable-export export appFOCCNDUuGhYPB2 Principles Cases Challenges Sources Stakeholders Strategies --key=",
             Sys.getenv("AIRTABLE_API_KEY"),
             " --json")
)

dir <- here::here("data/db/")

tables <- c("Principles", "strategies", "Cases", "Challenges", "Sources", "Stakeholders")

x <- purrr::map(tables, function(x){
  jsonlite::fromJSON(paste0(dir,x,".json"), flatten=T)}
)
names(x) <- tables

#col is a column name
#dflist is a list of dfs whose names are contained in some column names
#keys is a df column containing keys to look for

write_yamls <- function(df, df_name = names(df)) {
  df %>%
    rowwise() %>%
    group_map(function(x, y) {
      yaml_data <- purrr::map(names(x), function(col) {
        value <- x[[col]]
        if (is.factor(value) || is.character(value)) {
          # Convert factors or characters to string
          value <- as.character(value)
        } else if (is.numeric(value)) {
          # Convert numeric values to number
          value <- as.numeric(value)
        } else if (is.logical(value)) {
          # Convert logical values to boolean
          value <- as.logical(value)
        } else if (is.list(value)){
          # Convert list elements to strings
          value <- lapply(value, as.character)
          # Generate YAML list representation
          #value <- yaml::as.yaml(value)

        } else {
          # Handle other types as string
          value <- as.character(value)
        }
        set_names(list(value), col)
      })

      yaml_str <- yaml::as.yaml(do.call(c, yaml_data))

      # Customize the YAML format as needed, e.g., adding Hugo front matter
      yaml_str <- paste0("---\n", yaml_str, "\n---")

      return(yaml_str)
    }) %>%
    c() %>%
    purrr::map2(., seq_along(.), function(yaml, index) {
      readr::write_lines(yaml,
                         file = here::here("content/",
                                           tolower(df_name),
                                           "/",
                                           paste0(
                                             df$airtable_id[index],
                                             ".md")
                         ))
    })
}

#map over the list of tables and their names to extract and write data replacing crossrefs with links to other tables
purrr::map2(x, names(x), write_yamls)

#list2env(x, .GlobalEnv) #useful if you want to return the dfs to work with individually

#it would be useful once this is done to then:
#1, createa tibble to: list all files, and the replacement name
#2, find and replace all filenames with /[collection]/filename.md in the text
#3, within each named file, take the new yaml, and place it in the content itself
oldfiles <- list.files("content/",
                       full.names = TRUE,
                       recursive=T)
oldfiles <- oldfiles[grep(oldfiles,
                          pattern = "_index|example/|features/|setup/|templates/",
                          invert=T)]

filepaths <- tibble(
  oldfiles = oldfiles,
  collect = oldfiles %>% dirname() %>% basename(),
  key = basename(oldfiles) %>% fs::path_ext_remove(),
  newfiles = paste0(collect,"/", basename(oldfiles)))

lookup <- filepaths$newfiles %>% purrr::set_names(filepaths$key)

filepaths <- filepaths %>%
  mutate(
    content = map(filepaths$oldfiles, readLines) %>%
      map(., ~{
        stringr::str_replace_all(., "[:cntrl:]", "")
      }),
    titles = map(content, ~{
      ymlthis::yml_load(.) %>%
        ymlthis::yml_pluck("title")
    })
  )

####
#for each row
#get the content and replace the urls
#content %>% stringr::str_replace_all(., lookup)
#get where the yaml starts/end
#content %>% grep("---", .)
#get extracted_lines/frontmatter
#content %>% .[(line_indices[1] + 1):(line_indices[2] - 1)]
#then extract the links from the yaml header
#and for each link, lookup the title
filepaths2 <- filepaths %>%
  mutate(content = pmap(list(content), ~stringr::str_replace_all(., lookup)),
         bars = pmap(list(content), ~grep("---", .)),
         extract = pmap(list(content,bars), ~.x[(.y[1]+1):(.y[2]-1)]))

###
mylinkextractor <- function(contentolookin = content,
                            df=filepaths2){
  pathstolookfor = df$newfiles
  #first find the location of matching paths within our content
  qstring <- paste0(pathstolookfor, collapse = "|")
  contentolookin <- unlist(contentolookin)
  contentolookin <- contentolookin[!grepl(paste0("airtable_id:"), contentolookin)]
  paths <- contentolookin[grep(qstring, contentolookin)] %>%
    #then map over them, extracting the link bit, discarding the yaml key
    map(., ~{
      stringr::str_extract(., "(\\S+)$")})

  if (length(paths) == 0) {
    return(character())  # Return an empty character vector for empty paths
  }

  titles <- df %>%
    filter(newfiles %in% paths) %>%
    select(newfiles, titles) %>%
    tibble::deframe() %>%
    flatten()

  return(titles)
}

#ideally only do this for ones that actually have any linkss
#i tried adding a conditionl if(nchar(.) > 0){
#but it threw some opaque error
filepaths2 <- filepaths2 %>%
  mutate(mylinks = map(content, ~ mylinkextractor(.)))

filepaths2 <- filepaths2 %>%
  rowwise() %>%
  mutate(mylinks2 = list(map2(mylinks,names(mylinks), ~{
    paste0('<li> ',
           '[[',
           fs::path_ext_remove(.y),
           '|',
           fs::path_dir(.y),
           ': ',
           .x,
           ']]',
           ' </li>') %>%
      unlist() %>%
      unname()
  }
  )))


# filepaths2 <- filepaths2 %>%
#   mutate(mylinks = map(content, ~mylinkextractor(.)),
#          mylinks2 = map(mylinks, ~{
#            paste0('<li> ',
#                   '[[',.,']]',
#                   '(','{{< ref \"/content/', names(.), '\" >}} ',
#                   '\"',.,'\")',
#                   ' </li>') %>%
#              unlist() %>%
#              unname()
#          }))


#add the links to the content and write to file
writeyams <- function(content, mylinks, mypath = oldfiles, ...){
  readr::write_lines(c(content,
                       if(length(unlist(mylinks))>0){
                         c("\n### Links to\n",
                           "<ul>\n",
                           mylinks)
                       } else {
                         "."
                       },
                       "\n</ul>\n"),
                     file = mypath)}

for (i in 1:nrow(filepaths2)) {
  content = unlist(filepaths2$content[i])
  mylinks2 = unlist(filepaths2$mylinks2[i])
  oldfiles = filepaths2$oldfiles[i]

  writeyams(content, mylinks2, oldfiles)
}
# pmap
##############
############
###########


#
#
# map(filepaths$oldfiles, ~{
#   #get content, store path
#   mypath <- .
#   content <- readLines(.)
#
#   #remove control characters
#   content <- content %>%
#     stringr::str_replace_all(., "[:cntrl:]", "")
#
#   ptitle <- content %>%
#     ymlthis::yml_load(.) %>%
#     ymlthis::yml_pluck("title")
#
#   #replace keys with key+path
#   content <- content %>%
#     stringr::str_replace_all(lookup)
#
#
#   #limit to yaml
#   line_indices <- grep("---", content)
#   extracted_lines <- content[(line_indices[1] + 1):(line_indices[2] - 1)]
#   mylinks <- content[grep(paste0(
#     filepaths$newfiles, collapse="|"),
#     content)]
#   #find links
#   mylinks <- content[grep(paste0(
#     filepaths$newfiles, collapse="|"),
#     content)]
#
#   #extract the link portion
#   mylinks <- map(mylinks, ~{
#     stringr::str_extract(., "(\\S+)$")
#   })
#
#   #may need to add after the }} but before the ) '[',ptitle,']',
#   #write the links as ref links
#   mylinks <- map(mylinks, ~{
#     paste0('<li>',
#            '[',ptitle,']',
#            '(','{{< ref \"/content/', ., '\" >}}',')',
#            '</li>')
#   }) %>% unlist()
#
#   #add the links to the content and write to file
#   readr::write_lines(c(content,
#                        "\n### Links to\n",
#                        "<ul>\n",
#                        mylinks,
#                        "\n</ul>\n"),
#                      file = mypath)
#
# })
