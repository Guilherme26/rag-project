for FILE in awsdocs/*;
do
    rm $FILE/*
    cp $FILE/doc_source/* $FILE
    rm -r $FILE/doc_source
done
