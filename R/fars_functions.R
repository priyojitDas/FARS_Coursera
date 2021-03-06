require(roxygen2)
if(getRversion() >= "2.15.1")  utils::globalVariables(c("%>%", "STATE","MONTH","n","year"))
#' Read Fatality Analysis Reporting System data from csv file
#' 
#' This function reads data from a .csv file, where the name of the file is supplied as
#' the argument of the function
#' If file does not exist in the current working directory, then the function will give error.
#' 
#' @param filename A character string which is the name of the file
#' 
#' @return This function returns a data frame
#' 
#' @importFrom readr read_csv
#' @importFrom dplyr tbl_df
#' 
#' @export
fars_read <- function(filename) {
        if(!file.exists(filename))
                stop("file '", filename, "' does not exist")
        data <- suppressMessages({
                readr::read_csv(filename, progress = FALSE)
        })
        dplyr::tbl_df(data)
}

#' Create filename from a given particular year
#' 
#' This function creates a filename for a particular year, which can be modified in
#' the code by changing \code{year}
#' 
#' @param year A integer which depicts the year
#' 
#' @return This function returns a charcter string which is the name of the file
#' 
#' @export
make_filename <- function(year) {
        year <- as.integer(year)
        sprintf("accident_%d.csv.bz2", year)
}

#' Return a dataframe which contains year and month column for a set of years
#' 
#' This function creates a dataframe for a set of years, which can be modified in
#' the code by changing \code{years}
#' If the dataset does not conatin the given year, then it will give warning
#' 
#' @param years A list/vector containing years
#' 
#' @return This function returns a dataframe which contains two columns, month and year
#' 
#' @importFrom dplyr mutate select
#' 
#' @export
fars_read_years <- function(years) {
        lapply(years, function(year) {
                file <- make_filename(year)
                tryCatch({
                        dat <- fars_read(file)
                        dplyr::mutate(dat, year = year) %>% 
                                dplyr::select(MONTH, year)
                }, error = function(e) {
                        warning("invalid year: ", year)
                        return(NULL)
                })
        })
}

#' Return a dataframe which contains year and corresponding total entries, group by year and month
#' 
#' This function creates a dataframe for a set of years, which can be modified in
#' the code by changing \code{year}
#' 
#' @param years A list/vector containing years
#' 
#' @return This function returns a dataframe which contains year and corresponding 
#' total entries, group by year and month
#' 
#' @importFrom dplyr bind_rows group_by summarize 
#' @importFrom tidyr spread
#' 
#' @export
fars_summarize_years <- function(years) {
        dat_list <- fars_read_years(years)
        dplyr::bind_rows(dat_list) %>% 
                dplyr::group_by(year, MONTH) %>% 
                dplyr::summarize(n = n()) %>%
                tidyr::spread(year, n)
}

#' Plot a maps where the no of accidents are plotted on the state
#' 
#' This function generates a maps where the no of accidents are plotted on the 
#' state\code{year}
#' If wrong state code is given, then it will raise error
#' 
#' @param state.num A integer id of a state
#' @param year A integer which depicts the year
#' 
#' @importFrom maps map
#' @importFrom dplyr filter
#' @importFrom graphics points
#' 
#' @section Warning:
#' If wrong state code is given, then it will raise error
#' 
#' @export
fars_map_state <- function(state.num, year) {
        filename <- make_filename(year)
        data <- fars_read(filename)
        state.num <- as.integer(state.num)

        if(!(state.num %in% unique(data$STATE)))
                stop("invalid STATE number: ", state.num)
        data.sub <- dplyr::filter(data, STATE == state.num)
        if(nrow(data.sub) == 0L) {
                message("no accidents to plot")
                return(invisible(NULL))
        }
        is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
        is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
        with(data.sub, {
                maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
                          xlim = range(LONGITUD, na.rm = TRUE))
                graphics::points(LONGITUD, LATITUDE, pch = 46)
        })
}
