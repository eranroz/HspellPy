This is simple python wrapper to [Hspell](http://hspell.ivrix.org.il/).

Hspell is free Hebrew spellchecker and morphology engine.
This is just a python wrapping of Hspell.

You can get Hspell from:
	http://hspell.ivrix.org.il/

Hspell was written by Nadav Har'El and Dan Kenigsberg:
```
	nyh    @ math.technion.ac.il
	danken @   cs.technion.ac.il
```

# Install
1. Get Hspell: 
  1. Download Hspell: http://hspell.ivrix.org.il/
  2. Configure: ./configure --enable-linginfo
  3. Build: make
  4. Install: make install
2. python setup.py install

You can install HspellPy using pip:
```
pip install HspellPy
```

# Usage
Usage example (python 3)
```python
>>> import HspellPy
>>> speller = HspellPy.Hspell()
 
>>> speller.check_word('בית')       # check whether word exist in dictionary
True
>>> speller.check_word('הבית')      # words with prefix are also valid
True
>>> speller.check_word('בעעעע')     # invalid word
False
>>> 'בית' in speller                # syntactic sugar
True
>>> speller.try_correct('עדג')      # corrections (doesn't correct typo. see Hspell doc)
['הדג', 'עדה']
>>> speller.enum_splits('וילדותיה')   # list all splits of a word
>[WordEnumSplit(word='וילדותיה', baseword='ילדותיה', preflen=1, prefspec=60)]
>>> speller.linginfo('ילדה')        # morphology
[LinginfoWord(word='ילדה', linginfo='פ,נ,3,יחיד,עבר'), 
  LinginfoWord(word='ילדה', linginfo='ע,נ,יחיד'),
  LinginfoWord(word='ילדה', linginfo='ע,ז,יחיד,כינוי/נ,3,יחיד')]
```

