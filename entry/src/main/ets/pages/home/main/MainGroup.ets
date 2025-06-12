import { BaseItemDto } from "@ohpg/jellyfin";
import { MainCategory } from "./MainCategory";

export interface MainGroup {

  category: MainCategory

  items: Array<BaseItemDto>

}