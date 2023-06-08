#pacman::p_load_gh("matthewjrogers/rairtable")
# set_airtable_api_key('', install = TRUE)
#principles <- airtable('Principles', 'appFOCCNDUuGhYPB2')
#airtable_data <- read_airtable(principles, id_to_col = TRUE, max_rows = 50000)

pacman::p_load(magrittr, dplyr, tidyjson, purrr)

#shell("pip install airtable-export")
shell(paste0("airtable-export export appFOCCNDUuGhYPB2 Principles Cases Challenges Sources Stakeholders Strategies --key=",
             Sys.getenv("AIRTABLE_API_KEY"),
             " --yaml")
)

dir <- here::here("data/")
# fs::file_move("export", dir)

tables <- c("Principles", "Strategies", "Cases", "Challenges", "Sources", "Stakeholders")

combi <- purrr::map(tables, function(table){
  #table <<- table
  ymlthis::yml_load(readr::read_lines(glue::glue("{dir}/export/{table}.yml"))) %>%
    purrr::map(., ~{
      .x %>%
    ymlthis::yml_category(glue::glue("{table}")) %>%
    ymlthis::yml_toplevel(c("name" = .[["airtable_id"]])) %>%
    ymlthis::yml_discard("airtable_id") %>%
    ymlthis::yml_toplevel(list("tags" = as.list(
      stringr::str_replace_all(
        .[["Tags"]], " ", "-")))) %>%
    ymlthis::yml_discard("Tags") %>%
    ymlthis::yml_toplevel(c("created_at" = .[["airtable_createdTime"]])) %>%
    ymlthis::yml_discard("airtable_createdTime") %>%
    ymlthis::yml_toplevel(c("description" = stringr::str_replace_all(
      .[["Description"]], "\u00A0", ""))) %>%
    ymlthis::yml_toplevel(c("description" = stringr::str_replace_all(
          .[["description"]], "[:cntrl:]", ""))) %>%
        ymlthis::yml_discard("Description") %>%
        ymlthis::yml_discard("Attachments") %>%
        return(.)
    })
})

#I hate \u00A0
#"[:cntrl:]"

#don't name them or each ends up underneath its name
#names(combi) <- tables
#combi <- unname(combi)
#remove the toplevel

fields <- ymlthis:::flatten_yml_names(combi) %>% unique()
fields_manual <- c("title", "description", "created_at", "name", "Reference", "Link", "category")
fields <- base::Filter(function(field) !any(grepl(
  paste0(fields_manual, collapse="|"), field)), fields)

empty_item <- ymlthis::yml(author=F, date=F) %>%
  ymlthis::yml_toplevel(
    as.list(setNames(replicate(length(fields), list("test"), simplify = FALSE), fields))
  ) %>% ymlthis::yml_toplevel(c(
    as.list(setNames(replicate(length(fields_manual), "test", simplify = FALSE), fields_manual))
  )) %>% list()

#the arrays need to be of form:
#    list("Challenges" = list("test"))

combi <- combi %>% flatten() %>% append(empty_item, .)


convertStringToList <- function(value) {
  if (length(value) == 1) {
    as.list(value)
  } else {
    value
  }
}

combi <- map(combi, function(yaml_item) {
  map_at(yaml_item, fields, convertStringToList)
})

#write to file
yaml::write_yaml(combi, file = "data/collection.yml", fileEncoding = "UTF-8")

#I want to take this line and functionalise over fields
#ymlthis::yml_toplevel(list("tags" = as.list(.[["Tags"]]))) %>%
#check IF length == 1, if yes apply ^.
# co <- combi %>%
#    purrr::map(., ~{
#      yam_element <- unlist(.x)
#      yam_element %>%
#        ymlthis::as_yml() %>%
#         map(., function(key){
#           if(all(
#             length(yam_element[[key]])==1,
#             key %in% fields)){
#             ymlthis::yml_toplevel(c(
#                            list(field = as.list(.[[field]])))) %>%
#                            return()
#           }
#         })})
#
#          purrr::map(fields, function(field){
#           ymlthis::yml_toplevel(c(
#             list(field = as.list(.[[field]])))) %>%
#             return()
#         })
#   })
#

#ym <- yaml::read_yaml("data/test.yml")
