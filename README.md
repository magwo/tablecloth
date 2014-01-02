tablecloth
==========

Reusable Angular list/table data controller. Because writing this stuff over and over is boring.

A large portion of Angular use cases involve a browsable list/table of items that are sometimes editable, sometimes with pagination. So this controller (+coming service) mixin tries to provide the most common functionality, and the creator just supplies it with the smallest possible object structure that is unique for the use case. Usually this will be a data service that implements functions to retrieve data, and some handlers to react to responses and events, to support pagination and item deletion and editing. The data binding and DOM manipultaion via directives is considered outside of the scope of this project. In the basic case, the DOM portion will be pretty small and concise if using this controller mixin.
