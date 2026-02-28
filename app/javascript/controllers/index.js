// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

import TomSelectController from "./tom_select_controller"
application.register("tom-select", TomSelectController)
import DataTableController from "./datatable_controller"
application.register("datatable", DataTableController)