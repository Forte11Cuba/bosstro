// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Bosstro';

  @override
  String get navPending => 'Pendentes';

  @override
  String get navInProgress => 'Minhas disputas';

  @override
  String get navSettings => 'Configurações';

  @override
  String get noNodeSelected => 'Nenhum nó selecionado';

  @override
  String get pendingTitle => 'Disputas pendentes';

  @override
  String get pendingEmptyTitle => 'Nenhuma disputa aguardando';

  @override
  String get pendingEmptyBody =>
      'Nenhuma disputa deste nó está aguardando um solver. Quando uma operação abrir uma, ela aparecerá aqui para você assumir.';

  @override
  String get inProgressTitle => 'Suas disputas';

  @override
  String get inProgressEmptyTitle => 'Nenhuma disputa em andamento';

  @override
  String get inProgressEmptyBody =>
      'As disputas que você assumir aparecem aqui. Se uma solicitação para assumir ficou sem resposta, recupere a disputa.';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsGroupApp => 'App';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSheetTitle => 'Escolha um idioma';

  @override
  String get languageSystem => 'Idioma do sistema';

  @override
  String languageSystemDetail(String language) {
    return 'Igual ao do seu dispositivo: $language';
  }

  @override
  String get copied => 'Copiado';

  @override
  String get chatKeyCopied =>
      'Chave do chat copiada. Ela será apagada da área de transferência em 60 segundos.';

  @override
  String get chatCopyHint => 'Copiar a mensagem';

  @override
  String get idLabel => 'ID';

  @override
  String get copyIdHint => 'Copiar ID';

  @override
  String get easterEggWhitepaper =>
      '31 de outubro de 2008: nove páginas, sem pedir permissão a ninguém. Feliz Halloween.';

  @override
  String get easterEggGenesis =>
      'The Times 03/Jan/2009 Chancellor on brink of second bailout for banks';

  @override
  String get easterEggPizzaDay =>
      '22 de maio de 2010: 10.000 BTC por duas pizzas. Tomara que estivessem boas.';

  @override
  String get welcomeTitle => 'Resolva disputas do Mostro';

  @override
  String get welcomeBody =>
      'Assuma as disputas de um nó, converse com o comprador e o vendedor e encerre-as, pelo celular.';

  @override
  String get welcomeLogIn => 'Entrar';

  @override
  String get welcomeCreateAccount => 'Criar nova conta';

  @override
  String get welcomeKeyUnreadable =>
      'Não foi possível ler a chave salva neste celular. Entre de novo com sua chave secreta. Entrar com outra chave substitui a chave salva.';

  @override
  String get traderKeyWarning =>
      'Nunca use a chave com a qual você opera. Uma chave de solver que também é chave de operação vincula publicamente os dois papéis.';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginHeading => 'Sua chave secreta de solver';

  @override
  String get loginBody =>
      'Cole ou escaneie a chave secreta (nsec) cujo npub o operador do seu nó registrou como solver.';

  @override
  String get loginBodyPaste =>
      'Cole a chave secreta (nsec) cujo npub o operador do seu nó registrou como solver.';

  @override
  String get secretKeyHint => 'nsec1…';

  @override
  String get showSecretKey => 'Mostrar chave';

  @override
  String get hideSecretKey => 'Ocultar chave';

  @override
  String get pasteAction => 'Colar';

  @override
  String get scanQrAction => 'Escanear QR';

  @override
  String get clipboardEmpty => 'A área de transferência está vazia.';

  @override
  String get loginContinue => 'Continuar';

  @override
  String get keyErrorEmpty => 'Insira sua chave secreta.';

  @override
  String get keyErrorPublicKey =>
      'Isso é uma chave pública (npub). Para entrar, é preciso a chave secreta (nsec).';

  @override
  String get keyErrorInvalid =>
      'Esta não é uma chave secreta válida. Insira uma chave nsec1… ou sua forma hex de 64 caracteres.';

  @override
  String get loginConfirmHeading => 'Este é o npub registrado como solver?';

  @override
  String get loginConfirmBody =>
      'Compare-o com o npub que o operador do seu nó adicionou. Se não for o mesmo, esta chave não pode resolver disputas nesse nó.';

  @override
  String get loginConfirmAnswer => 'Sim, entrar';

  @override
  String get loginConfirmBack => 'Não, usar outra chave';

  @override
  String get keySaveFailed =>
      'Não foi possível salvar a chave neste celular. Tente novamente.';

  @override
  String get npubLabel => 'npub';

  @override
  String get secretKeyLabel => 'Chave secreta (nsec)';

  @override
  String get copyNpub => 'Copiar npub';

  @override
  String get copySecretKey => 'Copiar chave secreta';

  @override
  String get shareNpub => 'Compartilhar npub';

  @override
  String get npubQrLabel => 'Código QR do seu npub';

  @override
  String get scanTitle => 'Escanear QR';

  @override
  String get scanHint =>
      'Aponte a câmera para o código QR da sua chave secreta.';

  @override
  String get scanUnavailable =>
      'A câmera não está disponível. Volte e cole a chave.';

  @override
  String get createTitle => 'Criar nova conta';

  @override
  String get createKeyHeading => 'Sua nova chave secreta';

  @override
  String get createKeyBody =>
      'É a única forma de entrar nesta conta. Anote-a em um lugar seguro e privado: qualquer pessoa que a tenha pode resolver disputas como se fosse você.';

  @override
  String get createBackupConfirm =>
      'Salvei minha chave secreta em um lugar seguro';

  @override
  String get createContinue => 'Continuar';

  @override
  String get createNpubHeading => 'Seu npub';

  @override
  String get createNpubBody =>
      'Envie este npub ao operador do seu nó para que ele registre você como solver. Até lá, você pode ver as disputas, mas não pode assumi-las.';

  @override
  String get createDone => 'Escolher seu nó';

  @override
  String get settingsGroupKey => 'Chave de solver';

  @override
  String get settingsNpub => 'Seu npub';

  @override
  String get settingsBackup => 'Backup da chave secreta';

  @override
  String get settingsLogOut => 'Sair da conta';

  @override
  String get backupWarnTitle => 'Mostrar sua chave secreta?';

  @override
  String get backupWarnBody =>
      'Qualquer pessoa que a veja pode resolver disputas como se fosse você. Verifique se ninguém está olhando para a sua tela.';

  @override
  String get backupWarnAnswer => 'Mostrar chave secreta';

  @override
  String get cancel => 'Cancelar';

  @override
  String get backupTitle => 'Backup da chave secreta';

  @override
  String get backupBody =>
      'Guarde-a em um lugar seguro e privado. É a única forma de entrar nesta conta em outro celular.';

  @override
  String get backupUnavailable =>
      'Não foi possível ler a chave secreta neste celular.';

  @override
  String get logOutTitle => 'Sair da conta?';

  @override
  String get logOutBody =>
      'Sua chave secreta será removida deste celular. Sem um backup, você não poderá entrar nesta conta de novo.';

  @override
  String get logOutAnswer => 'Sair da conta';

  @override
  String get logOutFailed => 'Não foi possível sair da conta. Tente novamente.';

  @override
  String get secretKeyCopied =>
      'Chave secreta copiada. Ela será apagada da área de transferência em 60 segundos.';

  @override
  String linkOnline(int connected, int total) {
    return 'Online · $connected/$total relays';
  }

  @override
  String get linkConnecting => 'Conectando aos relays…';

  @override
  String get linkOffline => 'Sem conexão · nenhum relay responde';

  @override
  String get chooseNodeTitle => 'Escolha seu nó';

  @override
  String get chooseNodeBody =>
      'Escolha o nó Mostro cujo operador registrou sua chave como solver. Você pode mudar de nó depois em Configurações.';

  @override
  String get chooseNodeAppBar => 'Nó';

  @override
  String get nodeChipTrusted => 'Confiável';

  @override
  String get nodeChipCustom => 'Adicionado por você';

  @override
  String get nodeChipActive => 'Ativo';

  @override
  String get nodeAddOwn => 'Adicionar seu próprio nó';

  @override
  String get nodeInfoTooltip => 'Informações do nó';

  @override
  String nodeSwitched(String name) {
    return 'Agora usando $name';
  }

  @override
  String get nodeSelectFailed =>
      'Não foi possível mudar para este nó. Tente novamente.';

  @override
  String get nodeListFailed =>
      'Não foi possível carregar a lista de nós. Reinicie o app para tentar novamente.';

  @override
  String get addNodeTitle => 'Adicionar um nó';

  @override
  String get addNodeBody =>
      'Cole a chave pública do nó (npub ou hex). O operador dele pode passá-la para você.';

  @override
  String get addNodePubkeyLabel => 'Chave pública';

  @override
  String get addNodeNameLabel => 'Nome (opcional)';

  @override
  String get addNodeAnswer => 'Adicionar nó';

  @override
  String get nodeErrorInvalidPubkey =>
      'Insira uma chave pública válida (npub ou 64 caracteres hex).';

  @override
  String get nodeErrorPrivateKey =>
      'Isso é uma chave secreta — nunca a compartilhe. Insira a chave pública do nó.';

  @override
  String get nodeErrorAlreadyExists => 'Este nó já está na lista.';

  @override
  String get nodeErrorActive =>
      'Este é o seu nó ativo. Mude para outro nó antes de removê-lo.';

  @override
  String get nodeErrorStorage =>
      'Não foi possível salvar seus nós neste dispositivo.';

  @override
  String get nodeErrorGeneric => 'Algo deu errado. Tente novamente.';

  @override
  String get removeNodeAction => 'Remover nó';

  @override
  String get removeNodeTitle => 'Remover este nó?';

  @override
  String get removeNodeBody =>
      'Ele sai da sua lista. Você pode adicioná-lo de novo com a chave pública dele.';

  @override
  String get removeNodeAnswer => 'Remover nó';

  @override
  String get nodeRemoved => 'Nó removido';

  @override
  String get nodeInfoTitle => 'Informações do nó';

  @override
  String get nodeInfoUse => 'Usar este nó';

  @override
  String get nodeInfoGroupNode => 'Nó';

  @override
  String get nodeInfoPubkey => 'Chave pública';

  @override
  String get nodeInfoRegion => 'Região';

  @override
  String get nodeInfoWebsite => 'Site';

  @override
  String get nodeInfoAbout => 'Descrição';

  @override
  String get nodeInfoEmptyTitle => 'Ainda sem informações da instância';

  @override
  String get nodeInfoEmptyBody =>
      'Este nó não publicou as informações da instância nos relays que você usa, ou eles ainda não responderam. Elas são pedidas de novo sempre que você abre esta tela.';

  @override
  String get nodeInfoRefreshFailed =>
      'Os relays não responderam. Estas são as últimas informações vistas.';

  @override
  String get nodeInfoStale =>
      'Estas informações têm mais de 7 dias e podem estar desatualizadas.';

  @override
  String nodeInfoUnsupported(int version) {
    return 'Este nó usa o protocolo v$version. O Bosstro só usa o v2, então não pode resolver disputas nele.';
  }

  @override
  String get nodeInfoUpdatedNow => 'Atualizado agora mesmo';

  @override
  String nodeInfoUpdatedMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Atualizado há $count minutos',
      one: 'Atualizado há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Atualizado há $count horas',
      one: 'Atualizado há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String nodeInfoUpdatedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Atualizado há $count dias',
      one: 'Atualizado há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get nodeInfoGroupProtocol => 'Protocolo';

  @override
  String get nodeInfoProtocolVersion => 'Versão do protocolo';

  @override
  String get nodeInfoTransport => 'Transporte';

  @override
  String get nodeInfoGroupDaemon => 'Daemon do Mostro';

  @override
  String get nodeInfoVersion => 'Versão';

  @override
  String get nodeInfoCommit => 'Commit';

  @override
  String get nodeInfoMaxOrder => 'Ordem máxima';

  @override
  String get nodeInfoMinOrder => 'Ordem mínima';

  @override
  String get nodeInfoExpirationHours => 'Validade das ordens';

  @override
  String get nodeInfoExpirationSeconds => 'Validade das ordens aceitas';

  @override
  String get nodeInfoHoldWindow => 'Janela da fatura de retenção';

  @override
  String get nodeInfoHoldCltv => 'Delta CLTV da fatura de retenção';

  @override
  String get nodeInfoInvoiceWindow => 'Janela da fatura';

  @override
  String get nodeInfoMaxOrders => 'Máximo de ordens por resposta';

  @override
  String get nodeInfoFee => 'Taxa';

  @override
  String get nodeInfoPow => 'PoW exigido';

  @override
  String get nodeInfoPowFirst => 'PoW no primeiro contato';

  @override
  String get nodeInfoBonds => 'Depósitos antiabuso';

  @override
  String get nodeInfoGroupLightning => 'Nó Lightning';

  @override
  String get nodeInfoAlias => 'Alias';

  @override
  String get nodeInfoLnPubkey => 'Pubkey do nó';

  @override
  String get nodeInfoLndVersion => 'Versão do LND';

  @override
  String get nodeInfoChains => 'Cadeias';

  @override
  String get nodeInfoNetworks => 'Redes';

  @override
  String get nodeInfoUri => 'URI';

  @override
  String get nodeInfoGroupFiat => 'Moedas fiat';

  @override
  String get nodeInfoFiatAll => 'Todas as moedas são aceitas.';

  @override
  String get nodeInfoUnknown => 'Desconhecido';

  @override
  String get nodeInfoEnabled => 'Ativados';

  @override
  String get nodeInfoDisabled => 'Desativados';

  @override
  String unitSats(String amount) {
    return '$amount sats';
  }

  @override
  String unitHours(int count) {
    return '$count h';
  }

  @override
  String unitSeconds(int count) {
    return '$count s';
  }

  @override
  String unitBlocks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocos',
      one: '1 bloco',
    );
    return '$_temp0';
  }

  @override
  String unitBits(int count) {
    return '$count bits';
  }

  @override
  String unitPercent(String value) {
    return '$value%';
  }

  @override
  String get relaysTitle => 'Relays';

  @override
  String get relaysBody =>
      'O Bosstro se comunica com seu nó por meio destes relays. Os relays que seu nó anuncia são adicionados automaticamente.';

  @override
  String get relayStatusConnected => 'Conectado';

  @override
  String get relayStatusConnecting => 'Conectando';

  @override
  String get relayStatusDisconnected => 'Desconectado';

  @override
  String get relayStatusError => 'Recusado';

  @override
  String get relaySourceDefault => 'Padrão';

  @override
  String get relaySourceNode => 'Do seu nó';

  @override
  String get relaySourceUser => 'Adicionado por você';

  @override
  String get relayAdd => 'Adicionar relay';

  @override
  String get addRelayTitle => 'Adicionar um relay';

  @override
  String get addRelayLabel => 'Endereço do relay';

  @override
  String get addRelayAnswer => 'Adicionar relay';

  @override
  String get relayRemoveTooltip => 'Remover relay';

  @override
  String get removeRelayTitle => 'Remover este relay?';

  @override
  String get removeRelayBody =>
      'O Bosstro deixa de usá-lo. Um relay que seu nó anunciou só volta se você mesmo o adicionar.';

  @override
  String get removeRelayAnswer => 'Remover relay';

  @override
  String get relayErrorInvalidUrl =>
      'Insira um endereço de relay que comece com wss://.';

  @override
  String get relayErrorExists => 'Este relay já está na lista.';

  @override
  String get relayErrorLast =>
      'Este é o seu último relay. Adicione outro antes de removê-lo.';

  @override
  String get relaysNotRunningTitle => 'Os relays não iniciaram';

  @override
  String get relaysNotRunningBody =>
      'O Bosstro não conseguiu abrir a conexão com os relays. Reinicie o app para tentar novamente.';

  @override
  String get settingsGroupNode => 'Nó';

  @override
  String get settingsNode => 'Nó';

  @override
  String get settingsNodeNone => 'Escolher';

  @override
  String get settingsNodeInfo => 'Informações do nó';

  @override
  String get settingsRelays => 'Relays';

  @override
  String settingsRelaysValue(int connected, int total) {
    return '$connected/$total';
  }

  @override
  String get pendingNoNodeTitle => 'Escolha seu nó primeiro';

  @override
  String get pendingNoNodeBody =>
      'As disputas são lidas de um nó Mostro por vez. Escolha o nó em que você é solver.';

  @override
  String get pendingNoNodeAction => 'Escolher nó';

  @override
  String get loadingNodes => 'Carregando nós';

  @override
  String get loadingNodeInfo => 'Carregando as informações do nó';

  @override
  String get loadingRelays => 'Carregando relays';

  @override
  String get loadingDisputes => 'Carregando disputas';

  @override
  String get pendingLoadErrorTitle => 'Não foi possível ler as disputas';

  @override
  String get pendingLoadErrorBody =>
      'Algo deu errado ao ler as disputas deste nó neste celular. Feche e abra o Bosstro para tentar novamente.';

  @override
  String get disputeStatusInitiated => 'Aguardando solver';

  @override
  String get disputeStatusInProgress => 'Em andamento';

  @override
  String get disputeStatusSettled => 'Comprador pago';

  @override
  String get disputeStatusSellerRefunded => 'Vendedor reembolsado';

  @override
  String get disputeStatusReleased => 'Liberada pelo vendedor';

  @override
  String get disputeStatusCooperativelyCanceled =>
      'Cancelada pelas duas partes';

  @override
  String get disputeOpenedByBuyer => 'Aberta pelo comprador';

  @override
  String get disputeOpenedBySeller => 'Aberta pelo vendedor';

  @override
  String get disputeOpenedByUnknown => 'Não se sabe quem abriu';

  @override
  String get disputeOpenedJustNow => 'Aberta agora mesmo';

  @override
  String disputeOpenedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aberta há $count minutos',
      one: 'Aberta há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aberta há $count horas',
      one: 'Aberta há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String disputeOpenedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Aberta há $count dias',
      one: 'Aberta há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get disputeOpenedUnknown => 'Hora de abertura desconhecida';

  @override
  String disputeRowLabel(String id) {
    return 'Disputa $id';
  }

  @override
  String get close => 'Fechar';

  @override
  String get takeDisputeHint => 'Assumir a disputa';

  @override
  String get takeDisputeTitle => 'Assumir esta disputa?';

  @override
  String get takeDisputeBody =>
      'Você passa a ser o solver dela: o nó avisa o comprador e o vendedor, e a disputa vai para Suas disputas. Só assuma uma disputa que você possa acompanhar até o fim.';

  @override
  String get takeDisputeAnswer => 'Assumir a disputa';

  @override
  String get takeTakenSnack => 'Disputa assumida. Ela está em Suas disputas.';

  @override
  String get recoverAction => 'Recuperar';

  @override
  String get recoverTitle => 'Recuperar uma disputa';

  @override
  String get recoverNote =>
      'O nó não publica quem está com uma disputa. Por isso, esta lista mostra todas as disputas em andamento neste nó que não estão em Suas disputas neste celular: as suas cuja resposta se perdeu e as de outros solvers. Recupere-as uma de cada vez.';

  @override
  String get recoverEmptyTitle => 'Nada para recuperar';

  @override
  String get recoverEmptyBody =>
      'Nenhuma disputa em andamento deste nó está faltando em Suas disputas.';

  @override
  String get recoverDisputeHint => 'Recuperar a disputa';

  @override
  String get recoverDisputeTitle => 'Recuperar esta disputa?';

  @override
  String get recoverDisputeBody =>
      'O Bosstro pede esta disputa ao nó de novo. Se ela for sua, o nó envia os dados dela de volta. Se outro solver estiver com ela, o nó recusa, a menos que esse solver seja de somente leitura, como o Serbero, e sua chave possa pagar o comprador e reembolsar o vendedor: então a disputa passa a ser sua (uma tomada de controle).';

  @override
  String get recoverDisputeAnswer => 'Recuperar a disputa';

  @override
  String get recoverTakenSnack =>
      'Disputa recuperada. Ela está em Suas disputas.';

  @override
  String get notSolverTitle => 'Você não é solver neste nó';

  @override
  String get notSolverBody =>
      'Mude para o seu nó para resolver disputas. Se este for o seu nó, envie seu npub ao operador dele.';

  @override
  String get switchNodeAction => 'Mudar de nó';

  @override
  String get cannotTakeOverTitle => 'Outro solver está com esta disputa';

  @override
  String get cannotTakeOverBody =>
      'Só é possível assumir o controle de uma disputa que está com um solver de somente leitura, como o Serbero, e só um solver que pode pagar o comprador e reembolsar o vendedor pode fazer isso.';

  @override
  String get takeRefusedTitle => 'O nó não passou esta disputa para você';

  @override
  String get takeRefusedBody =>
      'Ele recusou a solicitação. Tente novamente mais tarde ou pergunte ao operador do nó.';

  @override
  String get takeRefusedNotFoundBody =>
      'O nó não tem mais a ordem desta disputa.';

  @override
  String get noAnswerTitle => 'O nó não respondeu';

  @override
  String get noAnswerBody =>
      'Sua solicitação pode ter chegado mesmo assim, então o Bosstro não a enviou de novo. Daqui a pouco, veja em Suas disputas ou peça de novo em Recuperar uma disputa.';

  @override
  String get takeFailedTitle => 'A solicitação não foi enviada';

  @override
  String get takeFailedBody =>
      'Nenhum relay a aceitou. Verifique sua conexão e os relays e tente novamente.';

  @override
  String get takeAlreadyTakingBody =>
      'Já há uma solicitação para esta disputa aguardando a resposta do nó.';

  @override
  String get takeClosedBody =>
      'Esta disputa está encerrada: não há nada para assumir.';

  @override
  String get takeUnknownBody =>
      'Esta disputa não está entre as disputas deste nó neste celular.';

  @override
  String get takeProtocolBody =>
      'Este nó anuncia outra versão do protocolo. O Bosstro só se comunica com nós do protocolo 2.';

  @override
  String get takeNodeInfoBody =>
      'O Bosstro não conseguiu ler as configurações deste nó, então não sabe a prova de trabalho que o nó exige. Verifique os relays e tente novamente.';

  @override
  String get disputeTakenJustNow => 'Assumida agora mesmo';

  @override
  String disputeTakenMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Assumida há $count minutos',
      one: 'Assumida há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Assumida há $count horas',
      one: 'Assumida há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String disputeTakenDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Assumida há $count dias',
      one: 'Assumida há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String disputeAmountSats(String amount) {
    return '$amount sats';
  }

  @override
  String disputeAmountFiat(String amount, String code) {
    return '$amount $code';
  }

  @override
  String get disputeAmountUnknown => 'Valor desconhecido';

  @override
  String get settingsSolverStatus => 'Solver neste nó';

  @override
  String get settingsSolverYes => 'Sim';

  @override
  String get settingsSolverNo => 'Não';

  @override
  String get settingsPermission => 'Permissão';

  @override
  String get permissionRead => 'Apenas mediar';

  @override
  String get permissionReadWrite => 'Mediar, pagar e reembolsar';

  @override
  String get disputeDetailTitle => 'Disputa';

  @override
  String get detailSegmentInfo => 'Info';

  @override
  String get detailSegmentBuyer => 'Comprador';

  @override
  String get detailSegmentSeller => 'Vendedor';

  @override
  String get detailSegmentsLabel => 'Seções da disputa';

  @override
  String get detailDisputeId => 'ID da disputa';

  @override
  String get detailOrderId => 'ID da ordem';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailOpenedBy => 'Aberta por';

  @override
  String get detailOpenedAt => 'Aberta em';

  @override
  String get detailTakenAt => 'Assumida em';

  @override
  String get detailAmount => 'Valor';

  @override
  String get detailCurrency => 'Moeda';

  @override
  String get detailFactsTitle => 'Informações da disputa';

  @override
  String get detailFiatAmount => 'Valor em fiat';

  @override
  String get detailPaymentMethod => 'Método de pagamento';

  @override
  String get detailPremium => 'Prêmio';

  @override
  String get detailFee => 'Taxa do nó';

  @override
  String get detailOrderKind => 'Tipo de ordem';

  @override
  String get detailBuyerKey => 'Chave de operação do comprador';

  @override
  String get detailSellerKey => 'Chave de operação do vendedor';

  @override
  String get detailPartyBuyer => 'Comprador';

  @override
  String get detailPartySeller => 'Vendedor';

  @override
  String get detailPartyUnknown => 'Desconhecido';

  @override
  String get detailOrderKindBuy => 'Ordem de compra';

  @override
  String get detailOrderKindSell => 'Ordem de venda';

  @override
  String detailPremiumValue(String value) {
    return '$value%';
  }

  @override
  String get detailNotYoursTitle => 'Esta disputa não é mais sua';

  @override
  String get detailNotYoursBody =>
      'O nó a reabriu, ou ela pertence a outra chave. Ela não está mais em Suas disputas.';

  @override
  String get chatSenderYou => 'Você';

  @override
  String get chatSenderBuyer => 'Comprador';

  @override
  String get chatSenderSeller => 'Vendedor';

  @override
  String get chatEmptyBuyerTitle => 'Nenhuma mensagem com o comprador';

  @override
  String get chatEmptySellerTitle => 'Nenhuma mensagem com o vendedor';

  @override
  String get chatEmptyBody =>
      'Só você e esta parte podem ler esta conversa. A outra parte não a vê.';

  @override
  String get chatNoPartyKeyTitle => 'Sem chat com esta parte';

  @override
  String get chatNoPartyKeyBody =>
      'A resposta do nó quando você assumiu a disputa não incluiu a chave desta parte, então o Bosstro não consegue falar com ela.';

  @override
  String get chatClosedNote =>
      'Esta disputa está encerrada. O chat é somente leitura.';

  @override
  String get chatComposerBuyerHint => 'Escreva para o comprador';

  @override
  String get chatComposerSellerHint => 'Escreva para o vendedor';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatSending => 'Enviando…';

  @override
  String get chatNotSent => 'Não enviada';

  @override
  String get chatRetry => 'Tentar novamente';

  @override
  String get chatErrorTooLong => 'A mensagem é longa demais. Divida-a em duas.';

  @override
  String get chatErrorClosed =>
      'Esta disputa está encerrada. O chat é somente leitura.';

  @override
  String get chatErrorNoRelays =>
      'Sem conexão com nenhum relay. Verifique sua conexão.';

  @override
  String get chatErrorNotYours => 'Esta disputa não é mais sua.';

  @override
  String get chatErrorGeneric => 'Não foi possível enviar a mensagem.';

  @override
  String get chatLoading => 'Carregando as mensagens';

  @override
  String chatMessageLabel(String sender, String time, String text) {
    return '$sender, $time: $text';
  }

  @override
  String get openDisputeHint => 'Abrir a disputa';

  @override
  String get chatAttach => 'Anexar um arquivo';

  @override
  String get attachSheetTitle => 'Anexar';

  @override
  String get attachSourcePhoto => 'Foto da galeria';

  @override
  String get attachSourceCamera => 'Tirar uma foto';

  @override
  String get attachSourcePdf => 'Documento PDF';

  @override
  String get attachSheetNote =>
      'O arquivo é criptografado neste dispositivo. Só você e esta parte podem abri-lo. JPEG, PNG ou PDF, até 25 MB.';

  @override
  String get attachConfirmTitle => 'Enviar este arquivo?';

  @override
  String attachConfirmBuyer(String name, String size) {
    return '$name ($size) vai para o comprador, criptografado. Uma foto é enviada sem a localização nem os dados da câmera.';
  }

  @override
  String attachConfirmSeller(String name, String size) {
    return '$name ($size) vai para o vendedor, criptografado. Uma foto é enviada sem a localização nem os dados da câmera.';
  }

  @override
  String get attachmentTooLarge => 'O arquivo tem mais de 25 MB.';

  @override
  String get attachmentUnsupported =>
      'Só é possível enviar imagens JPEG e PNG e documentos PDF.';

  @override
  String get attachmentInvalidImage => 'Não foi possível ler a imagem.';

  @override
  String get attachmentReadFailed => 'Não foi possível ler o arquivo.';

  @override
  String get attachmentUploadFailed =>
      'Não foi possível fazer o upload do arquivo. Verifique sua conexão e tente novamente.';

  @override
  String get attachmentSendFailed => 'Não foi possível enviar o arquivo.';

  @override
  String get attachmentUploading => 'Criptografando e enviando…';

  @override
  String get attachmentDiscard => 'Descartar';

  @override
  String get attachmentLoading => 'Descriptografando o arquivo';

  @override
  String get attachmentNotVerified => 'Não foi possível verificar o arquivo.';

  @override
  String get attachmentDownloadFailed => 'Não foi possível baixar o arquivo.';

  @override
  String get attachmentUnsupportedReceived =>
      'Este tipo de arquivo não pode ser aberto aqui.';

  @override
  String get attachmentOpenFailed => 'Não foi possível abrir o arquivo.';

  @override
  String attachmentImageLabel(String name) {
    return 'Imagem $name';
  }

  @override
  String get attachmentOpenImage => 'Abrir a imagem';

  @override
  String get attachmentSave => 'Salvar';

  @override
  String get attachmentSaveHint => 'Salvar o arquivo';

  @override
  String get attachmentSaved => 'Salvo';

  @override
  String get attachmentSaveFailed => 'Não foi possível salvar o arquivo.';

  @override
  String attachmentFileLabel(String name, String details) {
    return '$name, $details';
  }

  @override
  String get attachmentViewerZoomHint => 'Use dois dedos para ampliar';

  @override
  String get observerTitle => 'Chat entre as partes';

  @override
  String observerSharedByBuyer(String date) {
    return 'O comprador compartilhou a chave do chat dele em $date.';
  }

  @override
  String observerSharedBySeller(String date) {
    return 'O vendedor compartilhou a chave do chat dele em $date.';
  }

  @override
  String get observerPastedKey =>
      'Você colou uma chave do chat para esta disputa.';

  @override
  String get observerStoredOnly =>
      'Mensagens guardadas de uma leitura anterior. Cole a chave do chat de novo para buscar mensagens novas.';

  @override
  String get observerNoKey =>
      'Nenhuma das partes compartilhou a chave do chat ainda. Se uma delas a enviar para você por outro meio, cole-a aqui.';

  @override
  String get observerReadAction => 'Ler o chat entre as partes';

  @override
  String get observerPasteAction => 'Colar uma chave do chat';

  @override
  String get observerRefresh => 'Atualizar';

  @override
  String get observerReadOnlyBuyer =>
      'Somente leitura, com a chave que o comprador compartilhou.';

  @override
  String get observerReadOnlySeller =>
      'Somente leitura, com a chave que o vendedor compartilhou.';

  @override
  String get observerReadOnlyBoth =>
      'Somente leitura, com a chave que as duas partes compartilharam.';

  @override
  String get observerReadOnlyPasted =>
      'Somente leitura, com uma chave que você colou.';

  @override
  String get observerReadOnlyStored =>
      'Somente leitura: mensagens de uma leitura anterior.';

  @override
  String get observerNoKeyTitle => 'Ainda sem chave do chat';

  @override
  String get observerOpensNothingTitle =>
      'A chave não abre nenhuma mensagem desta disputa';

  @override
  String observerOpensNothingBody(String date) {
    return 'Nenhuma mensagem do comprador ou do vendedor desta disputa desde $date pode ser aberta com ela. Pode ser a chave de outra operação, ou eles não escreveram nesse período.';
  }

  @override
  String get observerReadFailedTitle => 'Não foi possível consultar os relays';

  @override
  String get observerReadFailedBody => 'Verifique a conexão e tente novamente.';

  @override
  String get observerNoPartyKeysTitle => 'Partes desconhecidas';

  @override
  String get observerNoPartyKeysBody =>
      'O nó não informou as chaves de operação do comprador e do vendedor, então nenhuma mensagem pode ser mostrada como deles.';

  @override
  String get observerPasteTitle => 'Colar uma chave do chat';

  @override
  String get observerPasteBody =>
      'Uma parte pode enviar para você a chave do chat dela com a outra parte. Com ela, você lê esse chat; nunca pode escrever nele.';

  @override
  String get observerPasteHint => '64 caracteres hexadecimais';

  @override
  String get observerPasteConfirm => 'Ler o chat';

  @override
  String get observerInvalidKey =>
      'Isso não é uma chave do chat: são 64 caracteres hexadecimais, sozinhos ou depois de “Shared key: ”.';

  @override
  String observerOpensNothingShort(String date) {
    return 'A chave não abre nenhuma mensagem desta disputa desde $date.';
  }

  @override
  String get observerNotYours => 'Esta disputa não é mais sua neste nó.';

  @override
  String get observerFileLocked =>
      'Não é possível abri-lo com uma chave do chat.';

  @override
  String get observerFileAdviceBuyer =>
      'Peça ao comprador que o envie para você no seu chat com ele.';

  @override
  String get observerFileAdviceSeller =>
      'Peça ao vendedor que o envie para você no seu chat com ele.';

  @override
  String get observerFileImage => 'Imagem';

  @override
  String get observerFileOther => 'Arquivo';

  @override
  String get resolveCardTitle => 'Resolver a disputa';

  @override
  String get resolveCardBody =>
      'Depois de ouvir as duas partes, decida para onde vão os sats. Isso não pode ser desfeito.';

  @override
  String get payBuyerAction => 'Pagar o comprador';

  @override
  String get refundSellerAction => 'Reembolsar o vendedor';

  @override
  String get payBuyerAnswer => 'Pagar o comprador';

  @override
  String get refundSellerAnswer => 'Reembolsar o vendedor';

  @override
  String get resolveReadOnlyNote =>
      'Sua chave de solver pode mediar neste nó, mas não pagar nem reembolsar. Peça ao operador permissão de leitura e escrita.';

  @override
  String get resolveUnansweredPayNote =>
      'Sua solicitação para pagar o comprador ficou sem resposta. O nó pode ter pago mesmo assim: confira o status da disputa antes de tentar novamente.';

  @override
  String get resolveUnansweredRefundNote =>
      'Sua solicitação para reembolsar o vendedor ficou sem resposta. O nó pode ter reembolsado mesmo assim: confira o status da disputa antes de tentar novamente.';

  @override
  String get payBuyerTitle => 'Pagar o comprador?';

  @override
  String get refundSellerTitle => 'Reembolsar o vendedor?';

  @override
  String get payBuyerRecipient => 'O comprador recebe';

  @override
  String get refundSellerRecipient => 'O vendedor recebe de volta';

  @override
  String payBuyerBreakdown(String amount, String fee) {
    return 'Os $amount da ordem menos a taxa do nó ($fee).';
  }

  @override
  String refundSellerBreakdown(String amount, String fee) {
    return 'Os $amount da ordem mais a taxa do nó ($fee), tal como o vendedor os bloqueou.';
  }

  @override
  String resolveTradeFiat(String fiat) {
    return 'Operação: $fiat';
  }

  @override
  String get payBuyerOtherSide =>
      'A fatura de retenção do vendedor é liquidada: o vendedor não recebe esses sats de volta.';

  @override
  String get refundSellerOtherSide =>
      'A fatura de retenção do vendedor é cancelada: o comprador não recebe nada desta operação.';

  @override
  String get resolveBondsUnknown =>
      'O Bosstro não sabe se este nó usa depósitos: não foi possível ler as informações dele, ou elas não informam isso. Se houver algum, nenhum será confiscado.';

  @override
  String get resolveIrreversible =>
      'Isso não pode ser desfeito. Uma vez enviada a solicitação, o Bosstro nunca a reenvia por conta própria.';

  @override
  String get resolveWaiting =>
      'Aguardando a resposta do nó. Mantenha o Bosstro aberto.';

  @override
  String get resolvedPaidTitle => 'Resolvida: você pagou o comprador';

  @override
  String get resolvedPaidBody =>
      'O nó liquidou a fatura de retenção do vendedor e está pagando o comprador. A disputa está encerrada.';

  @override
  String get resolvedRefundedTitle => 'Resolvida: você reembolsou o vendedor';

  @override
  String get resolvedRefundedBody =>
      'O nó cancelou a fatura de retenção do vendedor: os sats voltam para o vendedor. A disputa está encerrada.';

  @override
  String get resolvedCoopTitle => 'As partes já tinham cancelado';

  @override
  String get resolvedCoopBody =>
      'O comprador e o vendedor cancelaram a operação entre si antes da sua solicitação, então você não pagou nem reembolsou nada. A disputa está encerrada.';

  @override
  String get readOnlySolverTitle =>
      'Você não pode pagar nem reembolsar neste nó';

  @override
  String get takenOverTitle => 'Agora outro solver está com esta disputa';

  @override
  String get takenOverBody =>
      'O nó a passou para outro solver, então nada foi pago nem reembolsado. Ela saiu de Suas disputas.';

  @override
  String get notInDisputeTitle => 'Esta ordem não está mais em disputa';

  @override
  String get notInDisputeBody =>
      'Ela já foi paga, reembolsada ou liberada, talvez por uma solicitação anterior cuja resposta se perdeu. O status da disputa vai dizer como ela terminou.';

  @override
  String get resolveRefusedTitle => 'O nó recusou a solicitação';

  @override
  String get resolveRefusedBody =>
      'Nada foi pago nem reembolsado. Tente novamente mais tarde ou pergunte ao operador do nó.';

  @override
  String get resolveNoAnswerBody =>
      'Ele pode ter agido mesmo assim: os sats podem ter sido movimentados. O Bosstro não enviou a solicitação de novo. Confira o status da disputa antes de tentar novamente; ele muda assim que o nó o publicar.';

  @override
  String get resolveClosedBody =>
      'Esta disputa está encerrada: não há nada para resolver.';

  @override
  String get resolveNoOrderBody =>
      'O Bosstro não conhece a ordem desta disputa, e a solicitação precisa dela. Recupere a disputa para lê-la de novo.';

  @override
  String get resolveBackToDispute => 'Voltar à disputa';

  @override
  String get resolveGoToDisputes => 'Ir para Suas disputas';

  @override
  String get closedPaidBuyer => 'Você pagou o comprador';

  @override
  String get closedRefundedSeller => 'Você reembolsou o vendedor';

  @override
  String get closedCooperatively => 'As partes cancelaram antes da sua decisão';

  @override
  String get detailResult => 'Resultado';

  @override
  String get bondsTitle => 'Depósitos';

  @override
  String get bondsPickerHint =>
      'Este nó usa depósitos antiabuso. Escolha se algum depósito é confiscado, e de quem. Isso vai na mesma solicitação.';

  @override
  String get bondNoSlash => 'Não confiscar';

  @override
  String get bondNoSlashDetail => 'Cada depósito volta para o seu dono.';

  @override
  String get bondSlashBuyer => 'Confiscar do comprador';

  @override
  String get bondSlashBuyerDetail =>
      'O comprador perde o depósito dele; o vendedor pode resgatar a parte dele.';

  @override
  String get bondSlashSeller => 'Confiscar do vendedor';

  @override
  String get bondSlashSellerDetail =>
      'O vendedor perde o depósito dele; o comprador pode resgatar a parte dele.';

  @override
  String get bondSlashBoth => 'Confiscar dos dois';

  @override
  String get bondSlashBothDetail => 'Os dois perdem o depósito.';

  @override
  String get bondNotPostedTitle => 'Essa parte não tem depósito';

  @override
  String get bondNotPostedBody =>
      'O nó não tem depósito da parte de quem você escolheu confiscar, então nada foi pago nem reembolsado. Escolha outra opção de depósito.';

  @override
  String get bondChooseAgain => 'Escolher outra opção';

  @override
  String get resolvedSlashedBuyer => 'O depósito do comprador foi confiscado.';

  @override
  String get resolvedSlashedSeller => 'O depósito do vendedor foi confiscado.';

  @override
  String get resolvedSlashedBoth => 'Os dois depósitos foram confiscados.';

  @override
  String get detailBonds => 'Depósitos';

  @override
  String get detailPreviousStatus => 'Status antes da disputa';

  @override
  String get orderStatusActive => 'Ativa';

  @override
  String get orderStatusFiatSent => 'Fiat enviado';

  @override
  String myDisputesOpenSegment(int count) {
    return 'Em andamento · $count';
  }

  @override
  String myDisputesClosedSegment(int count) {
    return 'Encerradas · $count';
  }

  @override
  String get myDisputesSegmentsLabel => 'Disputas abertas ou encerradas';

  @override
  String get closedEmptyTitle => 'Nenhuma disputa encerrada ainda';

  @override
  String get closedEmptyBody =>
      'As disputas que você assume aparecem aqui quando são encerradas, seja por você ou porque as partes concluíram a negociação por conta própria.';

  @override
  String get disputeClosedJustNow => 'Encerrada agora mesmo';

  @override
  String disputeClosedMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encerrada há $count minutos',
      one: 'Encerrada há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String disputeClosedHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encerrada há $count horas',
      one: 'Encerrada há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String disputeClosedDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Encerrada há $count dias',
      one: 'Encerrada há 1 dia',
    );
    return '$_temp0';
  }
}
