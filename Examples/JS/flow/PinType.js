//  @flow
//
//  PinType.js
//  Autogenerated by plank
//
//  DO NOT EDIT - EDITS WILL BE OVERWRITTEN
//  @generated
//

import type { PlankDate, PlankURI } from './runtime.flow.js';
import type { BoardType } from './BoardType.js';
import type { ImageType } from './ImageType.js';
import type { UserType } from './UserType.js';

export type PinType = $Shape<{|
  +note: ?string,
  +media: ?{ +[string]: string },
  +counts: ?{ +[string]: number } /* Integer */,
  +description: ?string,
  +creator: { +[string]: UserType },
  +tags: ?Array<{}>,
  +attribution: ?{ +[string]: string },
  +board: ?BoardType,
  +visual_search_attrs: ?{},
  +color: ?string,
  +link: ?PlankURI,
  +id: string,
  +image: ?ImageType,
  +created_at: PlankDate,
  +url: ?PlankURI,
|}> & {
  id: string
};

