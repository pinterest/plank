//  @flow
//
//  BoardType.js
//  Autogenerated by plank
//
//  DO NOT EDIT - EDITS WILL BE OVERWRITTEN
//  @generated
//

import type { PlankDate, PlankURI } from './runtime.flow.js';
import type { ImageType } from './ImageType.js';
import type { UserType } from './UserType.js';

export type BoardType = $Shape<{|
  +contributors: ?Array<UserType>,
  +counts: ?{ +[string]: number } /* Integer */,
  +created_at: ?PlankDate,
  +creator: ?{ +[string]: string },
  +creator_url: ?PlankURI,
  +description: ?string,
  +image: ImageType,
  +name: ?string,
  +url: ?PlankURI,
|}> & {
  id: string
};

