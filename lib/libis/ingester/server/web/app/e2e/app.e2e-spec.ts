import { TeneoAppPage } from './app.po';

describe('teneo-app App', () => {
  let page: TeneoAppPage;

  beforeEach(() => {
    page = new TeneoAppPage();
  });

  it('should display message saying app works', () => {
    page.navigateTo();
    // expect(page.getParagraphText()).toEqual('teneo works!');
  });
});
