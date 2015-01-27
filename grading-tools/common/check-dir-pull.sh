cur=$PWD;
for student in ??????? ??????; do
    cd $cur/$student; 
    git pull;
    if [ -d $1 ]; then 
        cd $1; 
        echo $student;
    else 
        echo $student "has no SUBMISSION";
    fi;
    echo ;
    cd $cur;
done | grep SUBMISSION
