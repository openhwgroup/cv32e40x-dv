S->X PR review key points:

* "40x" Literals
    * Check for "40x" or "40X" in file names or content.
    * (This has crept in unnoticed before.)
* S-features
    * No PMP, no user mode, etc.
* X-features
    * mhpmcounters, xif, etc.
    * (Auto-merging sometimes tries to delete X-features.)
* Rejection Diff
    * Read the "rejection diff", to check that updates weren't accidentally omitted.
* Familiar/Relevant Changes
    * Skim through the diff and see if it generally makes sense.
* Test Results
    * Formal, sim, pass.
