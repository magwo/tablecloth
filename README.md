tablecloth
==========

Summary
=======
Reusable Angular list/table data controller.
Because writing this stuff over and over is boring.

A majority of Angular usages involve a browsable list/table of items that are sometimes editable. So this controller (+coming service) mixin tries to provide the most common functionality, and the creator just supplies it with the smallest possible object structure that is unique for the usage case. Usually this will be a data service that implements functinos to retrieve data, and some handlers to react to responses and events, to support pagination and item deletion and editing.
