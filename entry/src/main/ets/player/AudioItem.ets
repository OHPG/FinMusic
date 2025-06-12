import { BaseItemDto } from "@ohpg/jellyfin"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 17:09
 * @Version V1.0
 * @Description
 */
export interface AudioItem {

  id: string

  name: string

  url: string

  art: string

  extra: BaseItemDto
  
}