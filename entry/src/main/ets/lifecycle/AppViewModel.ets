import { ViewModel} from '@ohpg/fin-core'
import { Repository } from '../data/Repository'

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/6 23:28
 * @Version V1.0
 * @Description
 */
export class AppViewModel extends ViewModel {

  public readonly repository: Repository = AppStorage.get(Repository.REPOSITORY)!

  constructor(context: Context) {
    super(context)
  }

}