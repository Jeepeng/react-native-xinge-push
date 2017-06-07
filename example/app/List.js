/**
 * Created by Jeepeng on 2017/1/29.
 */

import React, { Component } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TouchableNativeFeedback,
  TouchableHighlight
} from 'react-native';

const Touchable = Platform.OS === 'android' ? TouchableNativeFeedback : TouchableHighlight;

class Item extends Component {

  render() {
    const { style, thumb, extra, arrow, onPress, children, _rightStyle } = this.props;
    return (
      <Touchable onPress={onPress} >
        <View style={[styles.item, style]}>
          { thumb }
          <View style={[styles.itemRight, _rightStyle]}>
            { typeof children === 'string' ?
              <Text style={styles.rightContentText}>{children}</Text>
              : <View style={styles.rightContent}>{children}</View>
            }
            { extra ?
              <View style={styles.rightRight}>
                { typeof extra === 'string' ?
                  <Text style={styles.rightExtraText}>{extra}</Text>
                  : <View style={styles.rightExtra}>{extra}</View>
                }
              </View> : null
            }
            { arrow }
          </View>
        </View>
      </Touchable>
    );
  }
}

class List extends Component {

  static Item = Item;

  render() {
    const { renderHeader, renderFooter, children, style } = this.props;
    return (
      <View style={[styles.list, style]}>
        {renderHeader && renderHeader()}
        <View style={styles.listWrapper}>
          {
            React.Children.map(children, (child, index) => {
              const extraRightStyle = (React.isValidElement(children) || children.length - 1 === index)
                  ? styles.itemRightWithoutBorder : {};
              return React.cloneElement(child, {
                _rightStyle: extraRightStyle,
              });
            })
          }
        </View>
        {renderFooter && renderFooter()}
      </View>
    );
  }
}

const styles = StyleSheet.create({
  list: {

  },
  listWrapper: {
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#e4ecf0',
    borderLeftWidth: 0,
    borderRightWidth: 0,
  },
  item: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  itemRight: {
    flexGrow: 1,
    minHeight: 45,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    alignSelf: 'stretch',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#e4ecf0',
  },
  itemRightWithoutBorder: {
    borderBottomWidth: 0,
  },
  rightContentText: {
    flex: 1,
    fontSize: 15,
    color: '#2b3d54'
  },
  rightContent: {
    flex: 1,
    alignSelf: 'stretch',
  },
  rightRight: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    alignSelf: 'stretch',
  },
  rightExtraText: {
    color: '#888',
    fontSize: 16,
  },
  rightExtra: {},

});

export default List;
