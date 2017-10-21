" syntax/dali.vim

" Match comments
syntax keyword daliTodos TODO XXX BUG FIXME NOTE

" Match boolean types
syntax match daliBoolean "\vtrue|false"

" Match comments
syntax match daliComment "\v\%.*$"

" Match number types
syntax match daliNumber "\v\d+"
syntax match daliNumber "\v\d+\.\d+"

" Match color types
syntax match daliColor "\v#[a-fA-F_0-9][a-fA-F_0-9][a-fA-F_0-9][a-fA-F_0-9][a-fA-F_0-9][a-fA-F_0-9]"

" Match string types
syntax match daliString "\v\".*\""

" Match language specific keywords
syntax keyword daliKeywords var func print return

" Match operators
syntax match daliOperator "\v\+"
syntax match daliOperator "\v\-"
syntax match daliOperator "\v\*"
syntax match daliOperator "\v/"
syntax match daliOperator "\v:"
syntax match daliOperator "\v\="
syntax match daliOperator "\v\<"
syntax match daliOperator "\v\>"
syntax match daliOperator "\v\&"
syntax match daliOperator "\v\|"

" Match punctuation
syntax match daliComma ","

" Match unrecognized characters
syntax match daliError "\v\@"
syntax match daliError "\v;"
syntax match daliError "\v'"

" Set highlights
highlight default link daliTodos Todo
highlight default link daliComment Comment

highlight default link daliBoolean Boolean 
highlight default link daliNumber Number
highlight default link daliColor Number
highlight default link daliString String

highlight default link daliKeywords Keyword
highlight default link daliOperator Operator
highlight default link daliComma Structure 
highlight default link daliError Error 
