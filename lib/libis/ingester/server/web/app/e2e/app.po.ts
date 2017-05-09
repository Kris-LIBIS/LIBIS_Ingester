import { browser, element, by } from 'protractor';

export class TeneoAppPage {
  navigateTo() {
    return browser.get('/');
  }

  getParagraphText() {
    return element(by.css('teneo-root h1')).getText();
  }
}
