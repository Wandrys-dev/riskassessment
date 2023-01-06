
<!-- README.md is generated from README.Rmd. Please edit that file -->

## Risk Assessment Shiny Application

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The Risk Assessment App is an interactive web application serving as a
front end application for the
[`riskmetric`](https://github.com/pharmaR/riskmetric) R package.
`riskmetric` is a framework to quantify risk by assessing a number of
metrics meant to evaluate development best practices, code
documentation, community engagement, and development sustainability. The
app and `riskmetric` aim to provide some context for validation within
regulated industries.

Furthermore, the app extends the functionalities of `riskmetric` by
allowing the reviewer to

-   analyze `riskmetric` output without the need to code in R,
-   comment on the value of individual metrics,
-   provide an overall assessment on the package (i.e., low, medium, or
    high risk) based on the output of the evaluating metrics cohort,
-   download a report with the package risk, metrics, and reviewer
    comments, and
-   store assessments on the database for future viewing.

The app also provides user authentication. There are two roles on the
app: regular user and admin. The latter can add/delete users, download
an entire copy of the database, and modify the metric weights.

For further information about the app, please refer to the
documentation.

<!---------------------------------------------------------------------------->
<!---------------------------------------------------------------------------->

### Our Approach to Validation

Validation can serve as an umbrella for various terms, and admittedly,
companies will diverge on what is the correct approach to validation.
The validation approach we followed during the development of the app is
based on the philosophy of the white paper set forth by the R Validation
Hub: [White Paper](https://www.pharmar.org/white-paper/).

<!---------------------------------------------------------------------------->
<!---------------------------------------------------------------------------->

### Documentation


We are currently working on improving the app and the documentation. In the meantime, please refer to the documentation
<a href="https://pharmar.github.io/riskassessment/Managing_Userids_and_Passwords" target="_blank">here</a>.

<!---------------------------------------------------------------------------->
<!---------------------------------------------------------------------------->

### Contributors/Authors

We would like to thank all the contributors!

Specially, we would like to thank the following contributors/authors.

-   [R Validation Hub](https://www.pharmar.org)
-   [Marly Gotti](https://www.marlygotti.com), Biogen, *Maintainer*
-   [Aaron Clark](https://www.linkedin.com/in/dataaaronclark/), Biogen,
    *Maintainer*
-   Robert Krajcik, Cytel, *Maintainer*
-   Maya Gans, Cytel
-   Aravind Reddy Kallem
-   Fission Labs India Pvt Ltd

*Note:* This app was made possible thanks to the [R Validation
Hub](https://www.pharmar.org/about/), a collaboration to support the
adoption of R within a biopharmaceutical regulatory setting.

<!---------------------------------------------------------------------------->
<!---------------------------------------------------------------------------->

### License

Please see the [License](LICENSE.md) file that lives alongside this
repo.
