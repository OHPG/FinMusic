import { Option, OptionDialog } from "@ohpg/fin-framework"
import { Repository } from "../../data/Repository"

@Component
export struct SourceMenu {

  @StorageLink("Repository") repository?: Repository = undefined

  @StorageProp("key_multi_source") multiSource?: boolean = false

  build() {

    if (this.multiSource) {
      SymbolGlyph($r('sys.symbol.discover_fill'))
        .fontSize($r('sys.float.Title_M'))
        .fontColor([$r('sys.color.font_primary')])
        .onClick(() => {
          this.selectSource()
        })
    }

  }

  selectSource() {
    let currentLibrary = this.repository?.getCurrentLibrary()
    let libraryArray = this.repository?.peekLibraryList()
    if (!currentLibrary || !libraryArray || libraryArray.length <= 0) {
      return
    }
    let selectLibraryDialog = new OptionDialog(this.getUIContext())
    let options = new Array<Option>()
    for (const library of libraryArray) {
      options.push({
        title: library.Name!,
        checked: currentLibrary.Id === library.Id
      })
    }
    selectLibraryDialog.setTitle($r('app.string.home_main_source'))
    selectLibraryDialog.setOptions(options)
    selectLibraryDialog.setOptionCallback((index) => {
      this.repository?.setCurrentLibrary(libraryArray![index])
    })
    selectLibraryDialog.show()
  }

}