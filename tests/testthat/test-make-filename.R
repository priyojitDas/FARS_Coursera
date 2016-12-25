context("make_filename")

test_that("make_filename works", {
  
  expect_equal(make_filename("1990"), "accident_1990.csv.bz2")
  
})