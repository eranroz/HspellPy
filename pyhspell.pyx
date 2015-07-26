cdef extern from "hspell.h":
    struct dict_radix
    struct corlist:
        pass
    #
    int hspell_init(dict_radix **dictp, int flags)
    void hspell_uninit(dict_radix *dictp)
    int hspell_check_word(dict_radix *dict, const char *word, int *preflen)
    void hspell_trycorrect(dict_radix *dict, const char *word, corlist *cl)

    int corlist_init(corlist *cl)
    int corlist_free(corlist *cl)
    int corlist_n(corlist *cl)
    char *corlist_str(corlist *cl, int i)

    ctypedef int hspell_word_split_callback_func(const char *word, const char *baseword, int preflen, int prefspec)
    int hspell_enum_splits(dict_radix *dict, const char *word, hspell_word_split_callback_func *enumf)
    void hspell_set_dictionary_path(const char *path)
    const char* hspell_get_dictionary_path()

    int HSPELL_OPT_HE_SHEELA, HSPELL_OPT_DEFAULT, HSPELL_OPT_LINGUISTICS

cdef extern from "linginfo.h":
    int linginfo_lookup(const char *word, char **desc, char **stem)
    char* linginfo_desc2text(char *text, const char *desc, int i)
    int linginfo_desc2ps(const char *desc, int i)
    char* linginfo_stem2text(const char *stem, int i)

__enum_splits_res = []

from collections import namedtuple
WordSplitRes = namedtuple('WordEnumSplit', ['word', 'baseword', 'preflen', 'prefspec'])
LinginfoWord = namedtuple('LinginfoWord', ['word', 'linginfo'])
cdef class Hspell(object):
    cdef dict_radix* hspell_dict
    cdef bint _debug

    def __init__(self, allow_he_sheela=False, linguistics=False, debug=False):
        """
        Initializes a new spell checker object
        :param allow_he_sheela:  allows he_sheela
        :param linguistics: allow linguistic data
        """
        cdef int flags
        cdef int init_err
        flags = HSPELL_OPT_DEFAULT
        if allow_he_sheela:
            flags |= HSPELL_OPT_HE_SHEELA
        if linguistics:
            flags |= HSPELL_OPT_LINGUISTICS

        init_err = hspell_init(&self.hspell_dict, flags)
        if init_err == -1:
            raise Exception('the dictionary files could not be read.')
        elif init_err < 0:
            raise Exception('Error init hspell %i' % init_err)

        self._debug = debug

    cdef __del__(self):
        hspell_uninit(self.hspell_dict)

    def check_word(self, word):
        """Checks whether a certain word is a correct Hebrew word, possibly with
         prefix particles attached in a syntacticly-correct manner

        :param word: a single Hebrew word
        :return: whether the word exist in dictionary
        """
        return self._check_word(word)

    def __contains__(self, word):
        """Checks whether a certain word is a correct Hebrew word, possibly with
        prefix particles attached in a syntacticly-correct manner

        Syntactic sugar similar to check_word

        :param word: word to check
        :return: whether the word exist in dictionary
        """
        return self.check_word(word)

    cdef _check_word(self, word):
        """Checks whether a certain word is a correct Hebrew word, possibly with
         prefix particles attached in a syntacticly-correct manner

        :param word: a single Hebrew word
        :return: whether the word exist in dictionary
        """
        cdef int res
        cdef char* word_to_check
        cdef int preflen

        #note: niqqud  characters, geresh or gershayim, must be removed from the word prior
        py_byte_string  = word.encode('iso8859-8')
        word_to_check = py_byte_string

        # preflen - the number of characters recognized as a prefix particle may be removed in future
        res = hspell_check_word(self.hspell_dict, word_to_check, &preflen)
        if res == 1:
            # word is correct
            return True

        return False

    def enum_splits(self, word):
        """Get all possible splitting of the given word into an optional prefix particle and a stand-alone word.

        For each possible (and legal, as some words cannot accept certain prefixes) split,
        is returned as list

        :param word: word to spit into an optional prefix particle and a stand-alone word.
        :return: all possible splittings of given word
        """
        global __enum_splits_res
        cdef int err_res

        py_byte_string  = word.encode('iso8859-8')

        err_res = hspell_enum_splits(self.hspell_dict, py_byte_string, _enum_splits_callback)
        res_list = __enum_splits_res
        __enum_splits_res = []
        return res_list

    def try_correct(self, word):
        """Tries to find a list of possible corrections for an incorrect word.

        Because in Hebrew the word density is high (a random string of letters, especially if short, has a high
        probability  of being a correct word), this function attempts to try corrections based on the assumption
        of a spelling error (replacement of letters that sound alike, missing or spurious immot qri'a),
        not typo (slipped finger on the keyboard, etc.)
        :param word: word to correct
        :return: correction list
        """
        return self._try_correct(word)

    cdef _try_correct(self, word):
        cdef corlist cl

        corlist_init (&cl)
        py_byte_string  = word.encode('iso8859-8')
        corrections = []
        hspell_trycorrect(self.hspell_dict, py_byte_string, &cl)

        if self._debug:
            print('%i' % corlist_n(&cl))

        for i in range(corlist_n(&cl)):
            correct = <bytes>corlist_str(&cl, i).decode('iso8859-8')
            corrections.append(correct)
        corlist_free(&cl)

        return corrections

    def linginfo(self, word):
        """
        Get linguistic information for a word
        :param word: word to get linguistic information for
        :return: a list of all possible linguistic information for a word
        """
        cdef int err_res
        cdef char *desc
        cdef char *stem
        cdef char buf[80]

        py_byte_string  = word.encode('iso8859-8')
        found = linginfo_lookup(py_byte_string, &desc, &stem)

        res = []
        if found:
            j = 0
            while True:
                if not linginfo_desc2text(buf, desc, j): break
                if linginfo_desc2ps(desc, j):
                    ling_data = (<bytes>buf).decode('iso8859-8')
                    word_mean = (<bytes>linginfo_stem2text(stem, j)).decode('iso8859-8')
                    res.append(LinginfoWord(word, ling_data))
                j += 1

        return res

cdef int _enum_splits_callback(const char* word, const char *baseword, int preflen, int prefspec):
    global __enum_splits_res

    word_decoded = (<bytes>word).decode('iso8859-8')
    baseword_decoded = (<bytes>baseword).decode('iso8859-8')

    __enum_splits_res.append(WordSplitRes(word_decoded, baseword_decoded, preflen, prefspec))

    return 0


def dictionary_path():
    """
    Path for Hebrew dictionary
    """
    cdef const char* path

    path = hspell_get_dictionary_path()
    return <bytes>path

def set_dictionary_path(dic_path):
    """
    Sets ath for Hebrew dictionary
    :param dic_path: new path for dictionary
    """
    cdef char* path

    py_byte_string  = dic_path.encode('iso8859-8')
    hspell_set_dictionary_path(py_byte_string)
