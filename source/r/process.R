#pacman::p_load_gh("matthewjrogers/rairtable")
# set_airtable_api_key('', install = TRUE)
#principles <- airtable('Principles', 'appFOCCNDUuGhYPB2')
#airtable_data <- read_airtable(principles, id_to_col = TRUE, max_rows = 50000)

pacman::p_load(magrittr, dplyr, tidyjson, purrr)

# Prompt the user for confirmation
confirmation <- readline("Are you sure you want to proceed? (y/n): ")

# Check the user's response
if (tolower(confirmation) == "y") {
  # Proceed with the desired action
  # ...
  # Your code here
  # ...


#shell("pip install airtable-export")
shell(paste0("airtable-export export appFOCCNDUuGhYPB2 Principles Cases Challenges Sources Stakeholders Strategies PrincipleCollation --key=",
             Sys.getenv("AIRTABLE_API_KEY"),
             " --yaml")
)

dir <- here::here("data/")
#consider adding
unlink("data/export", recursive = TRUE) # will delete directory called 'mydir'
fs::file_move("export", dir)

tables <- c("Principles", "Strategies", "Cases", "Challenges", "Sources", "Stakeholders", "PrincipleCollation")


combi <- purrr::map(tables, function(.x){
  table <- .x
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
        ymlthis::yml_discard(c(
          "Attachments","Fjeld","Jobin","Khan","Schiff","NOTES",
          "Selected term or map", "height", "thumbnails", "size")) %>%
        ymlthis::yml_toplevel(c("Fjeld_covered" = paste0(.[["Fjeld_covered"]]))) %>%
        ymlthis::yml_toplevel(c("Schiff_covered" = paste0(.[["Schiff_covered"]]))) %>%
        ymlthis::yml_toplevel(c("Khan_covered" = paste0(.[["Khan_covered"]]))) %>%
        ymlthis::yml_toplevel(c("Jobin_covered" = paste0(.[["Jobin_covered"]]))) %>%
        ymlthis::yml_toplevel(c("Coverage" = paste0(.[["Coverage"]]))) %>%
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
fields_manual <- c("title", "description", "created_at",
                   "name", "Reference", "Link", "category")
fields_numbers <- fields[c(grep("*_covered|Coverage", fields))]

fields <- base::Filter(function(field) !any(grepl(
  paste0(c(fields_manual, fields_numbers), collapse="|"), field)), fields)

empty_item <- ymlthis::yml(author=F, date=F) %>%
  ymlthis::yml_toplevel(
    as.list(setNames(replicate(length(fields), list("test"), simplify = FALSE), fields))
  ) %>% ymlthis::yml_toplevel(c(
    as.list(setNames(replicate(length(fields_manual), "test", simplify = FALSE), fields_manual))
  )) %>%
  ymlthis::yml_toplevel(c(
    as.list(setNames(replicate(length(fields_numbers), "0", simplify = FALSE), fields_numbers))
  )) %>%
  list()

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

print("Action confirmed!")
} else {
  # Perform any necessary actions if the user chooses not to proceed
  print("Action canceled.")
}
