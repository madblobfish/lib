# draw pictures with your git histoy!
# better and way cooler and more flexible version of python/git-heatmap

# gen data with:
#   git log --format=%%%aN,%aI --shortstat | tr '\n' ',' | sed -re 's/,?, ?/,/g' -e '1s/^%//' -e 's/,%/\n/g' -e 's/ files? changed,/,/g' | sed -re 's/^([a-zA-Z ]+,[^,]+,[0-9]+)(,([0-9]+) insertions?\(\+\))?(,([0-9]+) deletions?\\(\\-\\))?/\1,\3,\5/g' -e 's/(\+[0-9]{2}):([0-9]{2})/\1\2/g' -e '1 i\\name,date,files changed,insertions,deletions' > /tmp/date.csv

require(ggplot2)
datedata <- read.csv("/tmp/date.csv")

datedata$d <- strptime(datedata$date, "%Y-%m-%dT%H:%M:%S%z")
# table(datedata$d$mon)
# table(datedata$d$)
# table(datedata$d$hour)
matrixdata <- t(sapply(
	sort(unique(datedata$d$yday)),
	function(x) c(x, tabulate(c(23, subset(datedata, d$yday==x)$d$hour)))))
labels <- matrixdata[,1]
matrixdata <- matrixdata[,2:24]

# changes per hour
heatmap(matrixdata, Rowv=NA, Colv=NA, scale="column", labRow=labels)

# additions (insertions-deletions) on a certain day (over all years)
ggplot(datedata, aes(as.Date(d), insertions-deletions)) + stat_summary(fun.y=sum, geom="bar")
# number of commits per day
ggplot(datedata, aes(as.Date(d), 1, fill=name)) +
	stat_summary_bin(fun.y=sum, geom="bar", na.rm=TRUE, binwidth=1) +
	coord_cartesian(xlim=c(Sys.Date() - 67, Sys.Date())-429)
# commits per week
ggplot(datedata, aes(as.Date(date), fill=name)) + geom_histogram(binwidth=7)
# merges per person
ggplot(datedata, aes(name, as.numeric(is.na(files.changed)), fill=name)) +
	stat_summary(fun.y=sum, geom="bar", na.rm=TRUE)
# number of merges per week per person
ggplot(datedata, aes(as.Date(date), as.numeric(is.na(files.changed)), fill=name)) +
	stat_summary_bin(fun.y=sum, geom="bar", na.rm=TRUE, binwidth=7)
# who inserted how much lines
ggplot(datedata, aes(name, insertions-deletions, fill=name)) +
	stat_summary(fun.y=sum, geom="bar", na.rm=TRUE) +
	ylab("lines inserted")

ggplot(datedata, aes(as.Date(d), d$hour + d$min/60, size=insertions-deletions, color=name)) + geom_point()
