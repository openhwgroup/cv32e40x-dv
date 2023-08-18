S->X PR review key points:

* "40s" Literals
    * Check for "40s" or "40X" in file names or content.
    * (This has crept in unnoticed before.)
* S-features
    * No PMP, no user mode, etc.
* X-features
    * mhpmcounters, xif, etc.
    * (Auto-merging sometimes tries to delete X-features.)
* Rejection Diff
    * If the PRer adds a "rejection diff" it is useful to review.
    * Check that updates weren't accidentally omitted.
* Familiar/Relevant Changes
    * Skim through the diff and see if it generally makes sense.
* Test Results
    * Formal, sim, pass.
