This repository provides the replication package for the paper titled *An Empirical Study on the Survival Rate of GitHub Projects* sent to the *Mining Software Repositories 2022* conference, currently under review.

# Contents

The repository contains all the data required to generate the plots shown in the paper and, thus, come to the conclusions presented in the paper.
In the following, we briefly describe the content of this repository.

## `data` folder

This folder includes the data from our database extracted in CSV files.
For your convenience, we provide 5 types of CSV files, each divided by ecosystem (see suffixes `-laravel`, `-npm`, `-r` and `-wp` for each file). 
For instance, the data regarding the `allData-ECOSYSTEM.csv` for the Laravel ecosystem is in the `allData-laravel.csv` file.

These are the files included:

* `allData-ECOSYSTEM.csv`, which is the data dump from the database. Each row represents an event and includes the corresponding unique identifier (`id`), type of event (`type`), repository where the event was created (`repo_name`), the GitHub username authoring the event (`actor_login`), whether the author is a bot in GitHub (`isbot`) and the timestamp (`created_at`).

* `allData-Month-ECOSYSTEM.csv`, which has the events grouped by month. This file has a few processing from the previous data dump. The computed attributes are: `act_type`, which classifies the event types as `CODE` if the event is a commit or a pull request, and `NON_CODE` if it is an issue, a comment or a review; `date_month`, which tells the date of the month following the YYYY-MM format; and `activity`, which counts the number of events the group defined by the (1) repository, (2) event type, (3) whether it is a user or a bot, and (4) date.

* `evolutionPaths-ECOSYSTEM.csv`, which contains the evolution paths used in RQ1.

* `metadata-ECOSYSTEM.csv`, which, for each repository, has the information of whether it is a repository owned by a user or organization account (`repoType`), the tier of the community size (either 1, 2 or 3) (`sizeUsers`), the status at the end of the study (used in RQ2) (`status`) and the lifespan reported in months (`months`).

* `oracle-ECOSYSTEM.csv`, which complements `metadata.csv`providing the number of users in the community (see column `authors`), and the number of project resources created along its lifespan (see columns `Commits`, `Pulls`, `Issues`, `Comments` and `Reviews`).